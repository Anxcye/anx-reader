package com.shoutsocial.share_handler

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.os.SystemClock
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap

import androidx.annotation.NonNull
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

private const val kEventsChannel = "com.shoutsocial.share_handler/sharedMediaStream"

/** ShareHandlerPlugin */
class ShareHandlerPlugin : FlutterPlugin, Messages.ShareHandlerApi, EventChannel.StreamHandler, ActivityAware,
  PluginRegistry.NewIntentListener {
  private var initialMedia: Messages.SharedMedia? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null

  private var binding: ActivityPluginBinding? = null
  private lateinit var applicationContext: Context
  private val intentExecutor = Executors.newSingleThreadExecutor()
  private val transferExecutor = Executors.newCachedThreadPool()
  private val mainHandler = Handler(Looper.getMainLooper())
  private val activeStreams = ConcurrentHashMap<String, java.io.InputStream>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = flutterPluginBinding.applicationContext

    val messenger = flutterPluginBinding.binaryMessenger
    Messages.ShareHandlerApi.setup(messenger, this)

    eventChannel = EventChannel(messenger, kEventsChannel)
    eventChannel?.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Messages.ShareHandlerApi.setup(binding.binaryMessenger, null)
    activeStreams.values.forEach { stream -> runCatching { stream.close() } }
    activeStreams.clear()
    intentExecutor.shutdownNow()
    transferExecutor.shutdownNow()
  }

//  override fun getInitialSharedMedia(result: Result<SharedMedia>?) {
//    result?.let { _result -> {
//      initialMedia?.let { _media -> _result.success(_media) }
//    } }
//  }

//  override fun recordSentMessage(media: SharedMedia) {
//    val packageName = applicationContext.packageName
//    val shortcutTarget = "$packageName.dynamic_share_target"
//    val shortcutBuilder = ShortcutInfoCompat.Builder(applicationContext, media.conversationIdentifier ?: "").setShortLabel(media.speakableGroupName ?: "Unknown")
//      .setIsConversation()
//      .setCategories(setOf(shortcutTarget))
//      .setIntent(Intent(Intent.ACTION_DEFAULT))
//      .setLongLived(true)
//
//    val personBuilder = Person.Builder()
//      .setKey(media.conversationIdentifier)
//      .setName(media.speakableGroupName)
//
//    media.imageFilePath?.let {
//      val bitmap = BitmapFactory.decodeFile(it)
//      val icon = IconCompat.createWithAdaptiveBitmap(bitmap)
//      shortcutBuilder.setIcon(icon)
//      personBuilder.setIcon(icon)
//    }
//
//    val person = personBuilder.build()
//    shortcutBuilder.setPerson(person)
//
//    val shortcut = shortcutBuilder.build()
//
//    ShortcutManagerCompat.addDynamicShortcuts(applicationContext, listOf(shortcut))
//  }

  override fun getInitialSharedMedia(result: Messages.Result<Messages.SharedMedia>?) {
    result?.success(initialMedia)
  }

  override fun recordSentMessage(media: Messages.SharedMedia) {
    val packageName = applicationContext.packageName
    val intent = Intent(applicationContext, Class.forName("$packageName.MainActivity")).apply {
      action = Intent.ACTION_SEND
      putExtra("conversationIdentifier", media.conversationIdentifier)
    }
    val shortcutTarget = "$packageName.dynamic_share_target"
    val shortcutBuilder = ShortcutInfoCompat.Builder(applicationContext, media.conversationIdentifier ?: "")
      .setShortLabel(media.speakableGroupName ?: "Unknown")
      .setIsConversation()
      .setCategories(setOf(shortcutTarget))
      .setIntent(intent)
      .setLongLived(true)

    val personBuilder = Person.Builder()
      .setKey(media.conversationIdentifier)
      .setName(media.speakableGroupName)

    media.imageFilePath?.let {
      val bitmap = BitmapFactory.decodeFile(it)
      val icon = IconCompat.createWithAdaptiveBitmap(bitmap)
      shortcutBuilder.setIcon(icon)
      personBuilder.setIcon(icon)
    }

    val person = personBuilder.build()
    shortcutBuilder.setPerson(person)

    val shortcut = shortcutBuilder.build()

    ShortcutManagerCompat.addDynamicShortcuts(applicationContext, listOf(shortcut))
  }

  override fun resetInitialSharedMedia() {
    initialMedia = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.binding = binding
    binding.addOnNewIntentListener(this)
    val flags: Int = binding.activity.intent.flags
    if ((flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) {
      // The activity was launched from history
      Log.w("TAG", "Handle skip: The activity was launched from history")
    } else {
      handleIntent(binding.activity.intent, true)
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    binding?.removeOnNewIntentListener(this)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.binding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivity() {
    binding?.removeOnNewIntentListener(this)
  }

  override fun onNewIntent(intent: Intent): Boolean {
    handleIntent(intent, false)
    return false
  }

  private fun handleIntent(intent: Intent, initial: Boolean) {
    val intentSnapshot = Intent(intent)
    intentExecutor.execute {
      diagnosticLog(
        "INFO",
        "BookImport[android] stage=intent_received action=${intentSnapshot.action} initial=$initial",
      )
      val attachments: List<Messages.SharedAttachment>? = try {
        attachmentsFromIntent(intentSnapshot)
      } catch (e: Exception) {
        Log.e(LOG_TAG, "Error parsing shared attachments", e)
        diagnosticLog("SEVERE", "BookImport[android] stage=intent_parse_failed", e)
        null
      }

      val text: String? = when (intentSnapshot.action) {
        Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE ->
          intentSnapshot.getStringExtra(Intent.EXTRA_TEXT)
        else -> null
      }
      val conversationIdentifier =
        intentSnapshot.getStringExtra("android.intent.extra.shortcut.ID")
          ?: intentSnapshot.getStringExtra("conversationIdentifier")

      if (attachments == null && text == null && conversationIdentifier == null) {
        diagnosticLog("WARNING", "BookImport[android] stage=intent_empty")
        return@execute
      }

      diagnosticLog(
        "INFO",
        "BookImport[android] stage=intent_parsed attachments=${attachments?.size ?: 0}",
      )

      val mediaBuilder = Messages.SharedMedia.Builder()
      attachments?.let { mediaBuilder.setAttachments(it) }
      text?.let { mediaBuilder.setContent(it) }
      conversationIdentifier?.let { mediaBuilder.setConversationIdentifier(it) }
      val media = mediaBuilder.build()

      mainHandler.post {
        if (initial || eventSink == null) {
          synchronized(this) {
            initialMedia = media
          }
        }

        if (eventSink != null) {
          eventSink?.success(media.toMap())
        } else {
          Log.w(LOG_TAG, "Shared media cached until Flutter listener is ready")
        }
      }
    }
  }

  private fun attachmentsFromIntent(intent: Intent?): List<Messages.SharedAttachment>? {
    if (intent == null) return null

    // First, try to parse based on the specific intent action.
    when (intent.action) {
      Intent.ACTION_SEND -> {
        intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uri ->
          return listOfNotNull(attachmentForUriWithTimeout(uri))
        }
      }

      Intent.ACTION_SEND_MULTIPLE -> {
        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        val value = uris?.mapNotNull { uri -> attachmentForUriWithTimeout(uri) }?.toList()
        if (!value.isNullOrEmpty()) return value
      }

      Intent.ACTION_VIEW -> {
        // ACTION_VIEW is used when opening a file with "Open with" from other apps.
        attachmentsFromClipDataOrData(intent)?.let { return it }
      }
    }

    // Fallback: if no attachments were extracted yet, try clipData/data regardless of action.
    return attachmentsFromClipDataOrData(intent)
  }

  private fun attachmentsFromClipDataOrData(intent: Intent): List<Messages.SharedAttachment>? {
    val attachments = mutableListOf<Messages.SharedAttachment>()

    val clipData = intent.clipData
    if (clipData != null && clipData.itemCount > 0) {
      for (index in 0 until clipData.itemCount) {
        val uri = clipData.getItemAt(index).uri ?: continue
        attachmentForUriWithTimeout(uri)?.let { attachments.add(it) }
      }
    }

    intent.data?.let { dataUri ->
      val isAlreadyIncluded = clipData != null &&
        (0 until clipData.itemCount).any { clipData.getItemAt(it).uri == dataUri }
      if (!isAlreadyIncluded) {
        attachmentForUriWithTimeout(dataUri)?.let { attachments.add(it) }
      }
    }

    return attachments.takeIf { it.isNotEmpty() }
  }

  private fun attachmentForUriWithTimeout(uri: Uri): Messages.SharedAttachment? {
    val taskId = UUID.randomUUID().toString()
    val shortTaskId = taskId.take(8)
    diagnosticLog(
      "INFO",
      "BookImport[$shortTaskId] stage=uri_received scheme=${uri.scheme} authority=${uri.authority}",
    )
    val future = transferExecutor.submit<Messages.SharedAttachment?> {
      attachmentForUri(uri, taskId)
    }
    return try {
      future.get(TRANSFER_TIMEOUT_SECONDS, TimeUnit.SECONDS)
    } catch (e: TimeoutException) {
      activeStreams.remove(taskId)?.let { stream -> runCatching { stream.close() } }
      future.cancel(true)
      Log.e(LOG_TAG, "Timed out reading shared file from ${uri.authority ?: uri.scheme}")
      diagnosticLog("SEVERE", "BookImport[$shortTaskId] stage=copy_timeout")
      null
    } catch (e: Exception) {
      future.cancel(true)
      Log.e(LOG_TAG, "Failed reading shared file from ${uri.authority ?: uri.scheme}", e)
      diagnosticLog("SEVERE", "BookImport[$shortTaskId] stage=copy_failed", e)
      null
    }
  }

  private fun attachmentForUri(uri: Uri, taskId: String): Messages.SharedAttachment? {
    val contentResolver = applicationContext.contentResolver
    val mimeType = contentResolver.getType(uri)
    val metadata = readUriMetadata(contentResolver, uri, mimeType)
    diagnosticLog(
      "INFO",
      "BookImport[${taskId.take(8)}] stage=metadata_read file=${metadata.fileName} " +
        "declaredSize=${metadata.declaredSize ?: -1} mime=${mimeType ?: "unknown"}",
    )
    val copiedFile = copyUriToCache(contentResolver, uri, metadata, taskId) ?: return null

    return Messages.SharedAttachment.Builder()
      .setPath(copiedFile.absolutePath)
      .setType(getAttachmentType(mimeType))
      .build()
  }

  private data class UriMetadata(val fileName: String, val declaredSize: Long?)

  private fun readUriMetadata(
    contentResolver: ContentResolver,
    uri: Uri,
    mimeType: String?,
  ): UriMetadata {
    var displayName: String? = uri.lastPathSegment
    var declaredSize: Long? = null
    runCatching {
      contentResolver.query(
        uri,
        arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
        null,
        null,
        null,
      )?.use { cursor ->
        if (cursor.moveToFirst()) {
          cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            .takeIf { it >= 0 && !cursor.isNull(it) }
            ?.let { displayName = cursor.getString(it) }
          cursor.getColumnIndex(OpenableColumns.SIZE)
            .takeIf { it >= 0 && !cursor.isNull(it) }
            ?.let { declaredSize = cursor.getLong(it).takeIf { size -> size > 0L } }
        }
      }
    }.onFailure { error ->
      Log.w(LOG_TAG, "Shared provider did not expose file metadata", error)
    }

    var safeName = displayName
      ?.substringAfterLast('/')
      ?.substringAfterLast('\\')
      ?.replace(Regex("[\\u0000-\\u001f<>:\"/\\\\|?*]"), "_")
      ?.trim()
      ?.takeIf { it.isNotEmpty() }
      ?: "shared_${System.currentTimeMillis()}"
    if (!safeName.contains('.')) {
      MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)?.let { extension ->
        safeName += ".$extension"
      }
    }
    return UriMetadata(safeName, declaredSize)
  }

  private fun copyUriToCache(
    contentResolver: ContentResolver,
    uri: Uri,
    metadata: UriMetadata,
    taskId: String,
  ): File? {
    val importDir = File(applicationContext.cacheDir, SHARED_IMPORT_DIR)
    if (!importDir.exists() && !importDir.mkdirs()) {
      Log.e(LOG_TAG, "Unable to create shared import cache")
      return null
    }

    val writableBytes = (availableBytes(importDir) - MIN_FREE_BYTES).coerceAtLeast(0L)
    if (metadata.declaredSize != null && metadata.declaredSize > writableBytes) {
      Log.e(LOG_TAG, "Not enough cache space for ${metadata.fileName}")
      return null
    }

    val destination = File(importDir, "${UUID.randomUUID()}-${metadata.fileName}")
    val deadline = SystemClock.elapsedRealtime() +
      TimeUnit.SECONDS.toMillis(TRANSFER_TIMEOUT_SECONDS)
    var copiedBytes = 0L
    val startedAt = SystemClock.elapsedRealtime()
    diagnosticLog(
      "INFO",
      "BookImport[${taskId.take(8)}] stage=copy_start file=${metadata.fileName} " +
        "availableBytes=$writableBytes",
    )
    try {
      val input = contentResolver.openInputStream(uri)
        ?: throw IOException("ContentResolver returned no input stream")
      activeStreams[taskId] = input
      input.use { inputStream ->
        FileOutputStream(destination).use { outputStream ->
          val buffer = ByteArray(COPY_BUFFER_BYTES)
          while (true) {
            if (Thread.currentThread().isInterrupted ||
              SystemClock.elapsedRealtime() > deadline) {
              throw IOException("Shared file copy timed out")
            }
            val bytesRead = inputStream.read(buffer)
            if (bytesRead < 0) break
            copiedBytes += bytesRead
            if (copiedBytes > writableBytes) {
              throw IOException("Shared file exceeds available cache space")
            }
            outputStream.write(buffer, 0, bytesRead)
          }
        }
      }

      if (copiedBytes <= 0L || destination.length() != copiedBytes) {
        throw IOException("Shared file is empty or incomplete")
      }
      metadata.declaredSize?.let { expectedSize ->
        if (expectedSize != copiedBytes) {
          throw IOException(
            "Shared file size mismatch: expected $expectedSize, copied $copiedBytes",
          )
        }
      }
      if (!destination.isFile || !destination.canRead()) {
        throw IOException("Copied shared file is not readable")
      }
      FileInputStream(destination).use { stream ->
        if (stream.read() < 0) throw IOException("Copied shared file cannot be read back")
      }
      diagnosticLog(
        "INFO",
        "BookImport[${taskId.take(8)}] stage=copy_complete file=${metadata.fileName} " +
          "size=$copiedBytes durationMs=${SystemClock.elapsedRealtime() - startedAt}",
      )
      return destination
    } catch (e: Exception) {
      Log.e(LOG_TAG, "Failed to cache shared file ${metadata.fileName}", e)
      diagnosticLog(
        "SEVERE",
        "BookImport[${taskId.take(8)}] stage=copy_validation_failed file=${metadata.fileName} " +
          "copiedBytes=$copiedBytes",
        e,
      )
      if (destination.exists()) destination.delete()
      return null
    } finally {
      activeStreams.remove(taskId)?.let { stream -> runCatching { stream.close() } }
    }
  }

  @Suppress("DEPRECATION")
  private fun availableBytes(directory: File): Long {
    val stat = StatFs(directory.absolutePath)
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
      stat.availableBlocksLong * stat.blockSizeLong
    } else {
      stat.availableBlocks.toLong() * stat.blockSize.toLong()
    }
  }

  @Synchronized
  private fun diagnosticLog(level: String, message: String, error: Throwable? = null) {
    runCatching {
      val details = error?.let { " : ${it.javaClass.simpleName}: ${it.message}" } ?: ""
      val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
      }
      val line = "$level^*^ ${formatter.format(Date())}^*^ [$message]$details\n"
      File(applicationContext.filesDir, "anx_reader.log").appendText(line)
    }.onFailure { Log.w(LOG_TAG, "Unable to persist import diagnostic", it) }
  }

  // Function to determine the attachment type using the MIME type
  private fun getAttachmentType(mimeType: String?): Messages.SharedAttachmentType {
    return when {
      mimeType?.startsWith("image") == true -> Messages.SharedAttachmentType.image
      mimeType?.startsWith("video") == true -> Messages.SharedAttachmentType.video
      mimeType?.startsWith("audio") == true -> Messages.SharedAttachmentType.audio
      else -> Messages.SharedAttachmentType.file
    }
  }

  companion object {
    private const val LOG_TAG = "ShareHandler"
    private const val SHARED_IMPORT_DIR = "shared_imports"
    private const val TRANSFER_TIMEOUT_SECONDS = 180L
    private const val COPY_BUFFER_BYTES = 64 * 1024
    private const val MIN_FREE_BYTES = 16L * 1024L * 1024L
  }
}
