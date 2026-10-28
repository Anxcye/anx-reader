/// Unofficial Dart client for the Google AI Gemini Developer API and Vertex AI Gemini API with unified interface.
library;

// Auth
export 'src/auth/auth_provider.dart';
// Client
export 'src/client/config.dart'
    show ApiMode, ApiVersion, GoogleAIConfig, RetryPolicy;
export 'src/client/googleai_client.dart';
// Errors
export 'src/errors/exceptions.dart';
// Extensions (convenience helpers)
export 'src/extensions/candidate_extensions.dart';
export 'src/extensions/content_extensions.dart';
export 'src/extensions/generate_content_response_extensions.dart';
export 'src/extensions/interaction_extensions.dart';
// Live API
export 'src/live/live_client.dart';
export 'src/live/live_session.dart';
// Models - Auth Tokens
export 'src/models/auth/auth_token.dart';
export 'src/models/auth/create_auth_token_request.dart';
// Models - Batch API
export 'src/models/batch/batch_state.dart';
export 'src/models/batch/batch_stats.dart';
export 'src/models/batch/embed_content_batch.dart';
export 'src/models/batch/embed_content_batch_output.dart';
export 'src/models/batch/embed_content_batch_stats.dart';
export 'src/models/batch/generate_content_batch.dart';
export 'src/models/batch/generate_content_batch_output.dart';
export 'src/models/batch/inlined_embed_content_request.dart';
export 'src/models/batch/inlined_embed_content_requests.dart';
export 'src/models/batch/inlined_embed_content_response.dart';
export 'src/models/batch/inlined_embed_content_responses.dart';
export 'src/models/batch/inlined_request.dart';
export 'src/models/batch/inlined_requests.dart';
export 'src/models/batch/inlined_response.dart';
export 'src/models/batch/inlined_responses.dart';
export 'src/models/batch/input_config.dart';
export 'src/models/batch/input_embed_content_config.dart';
export 'src/models/batch/list_batches_response.dart';
export 'src/models/batch/status.dart';
// Models - Caching API
export 'src/models/caching/cached_content.dart';
export 'src/models/caching/cached_content_usage_metadata.dart';
export 'src/models/caching/list_cached_contents_response.dart';
// Models - Content
export 'src/models/content/blob.dart';
export 'src/models/content/candidate.dart';
export 'src/models/content/citation_metadata.dart';
export 'src/models/content/content.dart';
export 'src/models/content/file_data.dart';
export 'src/models/content/logprobs_result.dart';
export 'src/models/content/media_resolution.dart';
export 'src/models/content/part.dart';
// Models - Corpus API
export 'src/models/corpus/corpus.dart';
export 'src/models/corpus/document.dart';
export 'src/models/corpus/document_state.dart';
export 'src/models/corpus/list_corpora_response.dart';
export 'src/models/corpus/list_documents_response.dart';
// Models - Embeddings
export 'src/models/embeddings/batch_embed_contents_request.dart';
export 'src/models/embeddings/batch_embed_contents_response.dart';
export 'src/models/embeddings/content_embedding.dart';
export 'src/models/embeddings/embed_content_request.dart';
export 'src/models/embeddings/embed_content_response.dart';
export 'src/models/embeddings/task_type.dart';
// Models - Files API
export 'src/models/files/chunking_config.dart';
export 'src/models/files/file.dart';
export 'src/models/files/file_search_custom_metadata.dart';
export 'src/models/files/file_search_store.dart';
export 'src/models/files/file_source.dart';
export 'src/models/files/file_state.dart';
export 'src/models/files/generated_file.dart';
export 'src/models/files/import_file_request.dart';
export 'src/models/files/import_file_response.dart';
export 'src/models/files/list_file_search_stores_response.dart';
export 'src/models/files/list_files_response.dart';
export 'src/models/files/list_generated_files_response.dart';
export 'src/models/files/upload_to_file_search_store_request.dart';
export 'src/models/files/upload_to_file_search_store_response.dart';
export 'src/models/files/video_metadata.dart';
export 'src/models/files/white_space_config.dart';
// Models - Generation
export 'src/models/generation/answer_style.dart';
export 'src/models/generation/block_reason.dart';
export 'src/models/generation/count_tokens_request.dart';
export 'src/models/generation/count_tokens_response.dart';
export 'src/models/generation/generate_answer_request.dart';
export 'src/models/generation/generate_answer_response.dart';
export 'src/models/generation/generate_content_request.dart';
export 'src/models/generation/generate_content_response.dart';
export 'src/models/generation/generation_config.dart';
export 'src/models/generation/grounding_passage.dart';
export 'src/models/generation/grounding_passages.dart';
export 'src/models/generation/image_config.dart';
export 'src/models/generation/input_feedback.dart';
export 'src/models/generation/prompt_feedback.dart';
export 'src/models/generation/schema.dart';
export 'src/models/generation/thinking_config.dart';
export 'src/models/generation/thinking_level.dart';
// Models - Interactions API (Experimental)
export 'src/models/interactions/agent_config.dart';
export 'src/models/interactions/allowed_tools.dart';
export 'src/models/interactions/content/content.dart';
export 'src/models/interactions/deltas/deltas.dart';
export 'src/models/interactions/events/events.dart';
export 'src/models/interactions/generation_config.dart';
export 'src/models/interactions/interaction.dart';
export 'src/models/interactions/interaction_status.dart';
export 'src/models/interactions/modality_tokens.dart';
export 'src/models/interactions/response_modality.dart';
export 'src/models/interactions/speech_config.dart';
export 'src/models/interactions/thinking_level.dart';
export 'src/models/interactions/thinking_summaries.dart';
export 'src/models/interactions/tool_choice.dart';
export 'src/models/interactions/tool_choice_type.dart';
export 'src/models/interactions/tools/tools.dart';
export 'src/models/interactions/turn.dart';
export 'src/models/interactions/usage.dart';
// Models - Live API
export 'src/models/live/config/audio_transcription_config.dart';
export 'src/models/live/config/automatic_activity_detection.dart';
export 'src/models/live/config/context_window_compression_config.dart';
export 'src/models/live/config/live_config.dart';
export 'src/models/live/config/live_generation_config.dart';
export 'src/models/live/config/proactivity_config.dart';
export 'src/models/live/config/realtime_input_config.dart';
export 'src/models/live/config/session_resumption_config.dart';
export 'src/models/live/config/sliding_window.dart';
export 'src/models/live/config/speech_config.dart';
export 'src/models/live/config/transcription.dart';
export 'src/models/live/config/voice_config.dart';
export 'src/models/live/enums/activity_handling.dart';
export 'src/models/live/enums/end_sensitivity.dart';
export 'src/models/live/enums/start_sensitivity.dart';
export 'src/models/live/enums/turn_coverage.dart';
export 'src/models/live/messages/client/client_message.dart';
export 'src/models/live/messages/server/server_message.dart';
// Models - Metadata
export 'src/models/metadata/finish_reason.dart';
export 'src/models/metadata/grounding_chunk.dart';
export 'src/models/metadata/grounding_metadata.dart';
export 'src/models/metadata/grounding_support.dart';
export 'src/models/metadata/lat_lng.dart';
export 'src/models/metadata/maps.dart';
export 'src/models/metadata/modality_token_count.dart';
export 'src/models/metadata/place_answer_sources.dart';
export 'src/models/metadata/retrieval_config.dart';
export 'src/models/metadata/retrieval_metadata.dart';
export 'src/models/metadata/retrieved_context.dart';
export 'src/models/metadata/review_snippet.dart';
export 'src/models/metadata/search_entry_point.dart';
export 'src/models/metadata/segment.dart';
export 'src/models/metadata/usage_metadata.dart';
export 'src/models/metadata/web.dart';
// Models - Models API
export 'src/models/models/dataset.dart';
export 'src/models/models/hyperparameters.dart';
export 'src/models/models/list_models_response.dart';
export 'src/models/models/list_operations_response.dart';
export 'src/models/models/list_tuned_models_response.dart';
export 'src/models/models/model.dart';
export 'src/models/models/operation.dart';
export 'src/models/models/tuned_model.dart';
export 'src/models/models/tuning_task.dart';
export 'src/models/permissions/grantee_type.dart';
export 'src/models/permissions/list_permissions_response.dart';
// Models - Permissions API
export 'src/models/permissions/permission.dart';
export 'src/models/permissions/permission_role.dart';
export 'src/models/permissions/transfer_ownership_request.dart';
// Models - Prediction (Video Generation)
export 'src/models/prediction/media.dart';
export 'src/models/prediction/predict_long_running_generated_video_response.dart';
export 'src/models/prediction/predict_long_running_metadata.dart';
export 'src/models/prediction/predict_long_running_operation.dart';
export 'src/models/prediction/predict_long_running_request.dart';
export 'src/models/prediction/predict_long_running_response.dart';
export 'src/models/prediction/predict_request.dart';
export 'src/models/prediction/predict_response.dart';
// Models - Safety
export 'src/models/safety/harm_category.dart';
export 'src/models/safety/harm_probability.dart';
export 'src/models/safety/safety_rating.dart';
export 'src/models/safety/safety_setting.dart';
// Models - Tools
export 'src/models/tools/code_execution_result.dart';
export 'src/models/tools/computer_use.dart';
export 'src/models/tools/dynamic_retrieval_config.dart';
export 'src/models/tools/executable_code.dart';
export 'src/models/tools/file_search.dart';
export 'src/models/tools/function_call.dart';
export 'src/models/tools/function_calling_config.dart';
export 'src/models/tools/function_declaration.dart';
export 'src/models/tools/function_response.dart';
export 'src/models/tools/google_maps.dart';
export 'src/models/tools/google_search_retrieval.dart';
export 'src/models/tools/mcp_server.dart';
export 'src/models/tools/streamable_http_transport.dart';
export 'src/models/tools/tool.dart';
export 'src/models/tools/tool_config.dart';
// Utilities
export 'src/utils/lro_poller.dart';
export 'src/utils/paginator.dart';
