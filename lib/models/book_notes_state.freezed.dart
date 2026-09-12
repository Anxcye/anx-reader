// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_notes_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotesSortMode {
  NotesSortField get field;
  SortDirection get direction;

  /// Create a copy of NotesSortMode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotesSortModeCopyWith<NotesSortMode> get copyWith =>
      _$NotesSortModeCopyWithImpl<NotesSortMode>(
          this as NotesSortMode, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NotesSortMode &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.direction, direction) ||
                other.direction == direction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field, direction);

  @override
  String toString() {
    return 'NotesSortMode(field: $field, direction: $direction)';
  }
}

/// @nodoc
abstract mixin class $NotesSortModeCopyWith<$Res> {
  factory $NotesSortModeCopyWith(
          NotesSortMode value, $Res Function(NotesSortMode) _then) =
      _$NotesSortModeCopyWithImpl;
  @useResult
  $Res call({NotesSortField field, SortDirection direction});
}

/// @nodoc
class _$NotesSortModeCopyWithImpl<$Res>
    implements $NotesSortModeCopyWith<$Res> {
  _$NotesSortModeCopyWithImpl(this._self, this._then);

  final NotesSortMode _self;
  final $Res Function(NotesSortMode) _then;

  /// Create a copy of NotesSortMode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? direction = null,
  }) {
    return _then(_self.copyWith(
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as NotesSortField,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as SortDirection,
    ));
  }
}

/// @nodoc

class _NotesSortMode extends NotesSortMode {
  const _NotesSortMode({required this.field, required this.direction})
      : super._();

  @override
  final NotesSortField field;
  @override
  final SortDirection direction;

  /// Create a copy of NotesSortMode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotesSortModeCopyWith<_NotesSortMode> get copyWith =>
      __$NotesSortModeCopyWithImpl<_NotesSortMode>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NotesSortMode &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.direction, direction) ||
                other.direction == direction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field, direction);

  @override
  String toString() {
    return 'NotesSortMode(field: $field, direction: $direction)';
  }
}

/// @nodoc
abstract mixin class _$NotesSortModeCopyWith<$Res>
    implements $NotesSortModeCopyWith<$Res> {
  factory _$NotesSortModeCopyWith(
          _NotesSortMode value, $Res Function(_NotesSortMode) _then) =
      __$NotesSortModeCopyWithImpl;
  @override
  @useResult
  $Res call({NotesSortField field, SortDirection direction});
}

/// @nodoc
class __$NotesSortModeCopyWithImpl<$Res>
    implements _$NotesSortModeCopyWith<$Res> {
  __$NotesSortModeCopyWithImpl(this._self, this._then);

  final _NotesSortMode _self;
  final $Res Function(_NotesSortMode) _then;

  /// Create a copy of NotesSortMode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field = null,
    Object? direction = null,
  }) {
    return _then(_NotesSortMode(
      field: null == field
          ? _self.field
          : field // ignore: cast_nullable_to_non_nullable
              as NotesSortField,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as SortDirection,
    ));
  }
}

/// @nodoc
mixin _$BookNotesState {
  Book get book;
  List<BookNote> get allNotes;
  List<BookNote> get visibleNotes;
  NotesSortMode get viewSortMode;
  NotesSortMode get exportSortMode;
  bool get showBookmarks;
  Set<String> get enabledTypeColors;
  Set<int> get selectedNoteIds;

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookNotesStateCopyWith<BookNotesState> get copyWith =>
      _$BookNotesStateCopyWithImpl<BookNotesState>(
          this as BookNotesState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookNotesState &&
            (identical(other.book, book) || other.book == book) &&
            const DeepCollectionEquality().equals(other.allNotes, allNotes) &&
            const DeepCollectionEquality()
                .equals(other.visibleNotes, visibleNotes) &&
            (identical(other.viewSortMode, viewSortMode) ||
                other.viewSortMode == viewSortMode) &&
            (identical(other.exportSortMode, exportSortMode) ||
                other.exportSortMode == exportSortMode) &&
            (identical(other.showBookmarks, showBookmarks) ||
                other.showBookmarks == showBookmarks) &&
            const DeepCollectionEquality()
                .equals(other.enabledTypeColors, enabledTypeColors) &&
            const DeepCollectionEquality()
                .equals(other.selectedNoteIds, selectedNoteIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      book,
      const DeepCollectionEquality().hash(allNotes),
      const DeepCollectionEquality().hash(visibleNotes),
      viewSortMode,
      exportSortMode,
      showBookmarks,
      const DeepCollectionEquality().hash(enabledTypeColors),
      const DeepCollectionEquality().hash(selectedNoteIds));

  @override
  String toString() {
    return 'BookNotesState(book: $book, allNotes: $allNotes, visibleNotes: $visibleNotes, viewSortMode: $viewSortMode, exportSortMode: $exportSortMode, showBookmarks: $showBookmarks, enabledTypeColors: $enabledTypeColors, selectedNoteIds: $selectedNoteIds)';
  }
}

/// @nodoc
abstract mixin class $BookNotesStateCopyWith<$Res> {
  factory $BookNotesStateCopyWith(
          BookNotesState value, $Res Function(BookNotesState) _then) =
      _$BookNotesStateCopyWithImpl;
  @useResult
  $Res call(
      {Book book,
      List<BookNote> allNotes,
      List<BookNote> visibleNotes,
      NotesSortMode viewSortMode,
      NotesSortMode exportSortMode,
      bool showBookmarks,
      Set<String> enabledTypeColors,
      Set<int> selectedNoteIds});

  $NotesSortModeCopyWith<$Res> get viewSortMode;
  $NotesSortModeCopyWith<$Res> get exportSortMode;
}

/// @nodoc
class _$BookNotesStateCopyWithImpl<$Res>
    implements $BookNotesStateCopyWith<$Res> {
  _$BookNotesStateCopyWithImpl(this._self, this._then);

  final BookNotesState _self;
  final $Res Function(BookNotesState) _then;

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? book = null,
    Object? allNotes = null,
    Object? visibleNotes = null,
    Object? viewSortMode = null,
    Object? exportSortMode = null,
    Object? showBookmarks = null,
    Object? enabledTypeColors = null,
    Object? selectedNoteIds = null,
  }) {
    return _then(_self.copyWith(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      allNotes: null == allNotes
          ? _self.allNotes
          : allNotes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
      visibleNotes: null == visibleNotes
          ? _self.visibleNotes
          : visibleNotes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
      viewSortMode: null == viewSortMode
          ? _self.viewSortMode
          : viewSortMode // ignore: cast_nullable_to_non_nullable
              as NotesSortMode,
      exportSortMode: null == exportSortMode
          ? _self.exportSortMode
          : exportSortMode // ignore: cast_nullable_to_non_nullable
              as NotesSortMode,
      showBookmarks: null == showBookmarks
          ? _self.showBookmarks
          : showBookmarks // ignore: cast_nullable_to_non_nullable
              as bool,
      enabledTypeColors: null == enabledTypeColors
          ? _self.enabledTypeColors
          : enabledTypeColors // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedNoteIds: null == selectedNoteIds
          ? _self.selectedNoteIds
          : selectedNoteIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ));
  }

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotesSortModeCopyWith<$Res> get viewSortMode {
    return $NotesSortModeCopyWith<$Res>(_self.viewSortMode, (value) {
      return _then(_self.copyWith(viewSortMode: value));
    });
  }

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotesSortModeCopyWith<$Res> get exportSortMode {
    return $NotesSortModeCopyWith<$Res>(_self.exportSortMode, (value) {
      return _then(_self.copyWith(exportSortMode: value));
    });
  }
}

/// @nodoc

class _BookNotesState extends BookNotesState {
  const _BookNotesState(
      {required this.book,
      required final List<BookNote> allNotes,
      required final List<BookNote> visibleNotes,
      required this.viewSortMode,
      required this.exportSortMode,
      required this.showBookmarks,
      required final Set<String> enabledTypeColors,
      required final Set<int> selectedNoteIds})
      : _allNotes = allNotes,
        _visibleNotes = visibleNotes,
        _enabledTypeColors = enabledTypeColors,
        _selectedNoteIds = selectedNoteIds,
        super._();

  @override
  final Book book;
  final List<BookNote> _allNotes;
  @override
  List<BookNote> get allNotes {
    if (_allNotes is EqualUnmodifiableListView) return _allNotes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allNotes);
  }

  final List<BookNote> _visibleNotes;
  @override
  List<BookNote> get visibleNotes {
    if (_visibleNotes is EqualUnmodifiableListView) return _visibleNotes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_visibleNotes);
  }

  @override
  final NotesSortMode viewSortMode;
  @override
  final NotesSortMode exportSortMode;
  @override
  final bool showBookmarks;
  final Set<String> _enabledTypeColors;
  @override
  Set<String> get enabledTypeColors {
    if (_enabledTypeColors is EqualUnmodifiableSetView)
      return _enabledTypeColors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_enabledTypeColors);
  }

  final Set<int> _selectedNoteIds;
  @override
  Set<int> get selectedNoteIds {
    if (_selectedNoteIds is EqualUnmodifiableSetView) return _selectedNoteIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedNoteIds);
  }

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookNotesStateCopyWith<_BookNotesState> get copyWith =>
      __$BookNotesStateCopyWithImpl<_BookNotesState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookNotesState &&
            (identical(other.book, book) || other.book == book) &&
            const DeepCollectionEquality().equals(other._allNotes, _allNotes) &&
            const DeepCollectionEquality()
                .equals(other._visibleNotes, _visibleNotes) &&
            (identical(other.viewSortMode, viewSortMode) ||
                other.viewSortMode == viewSortMode) &&
            (identical(other.exportSortMode, exportSortMode) ||
                other.exportSortMode == exportSortMode) &&
            (identical(other.showBookmarks, showBookmarks) ||
                other.showBookmarks == showBookmarks) &&
            const DeepCollectionEquality()
                .equals(other._enabledTypeColors, _enabledTypeColors) &&
            const DeepCollectionEquality()
                .equals(other._selectedNoteIds, _selectedNoteIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      book,
      const DeepCollectionEquality().hash(_allNotes),
      const DeepCollectionEquality().hash(_visibleNotes),
      viewSortMode,
      exportSortMode,
      showBookmarks,
      const DeepCollectionEquality().hash(_enabledTypeColors),
      const DeepCollectionEquality().hash(_selectedNoteIds));

  @override
  String toString() {
    return 'BookNotesState(book: $book, allNotes: $allNotes, visibleNotes: $visibleNotes, viewSortMode: $viewSortMode, exportSortMode: $exportSortMode, showBookmarks: $showBookmarks, enabledTypeColors: $enabledTypeColors, selectedNoteIds: $selectedNoteIds)';
  }
}

/// @nodoc
abstract mixin class _$BookNotesStateCopyWith<$Res>
    implements $BookNotesStateCopyWith<$Res> {
  factory _$BookNotesStateCopyWith(
          _BookNotesState value, $Res Function(_BookNotesState) _then) =
      __$BookNotesStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Book book,
      List<BookNote> allNotes,
      List<BookNote> visibleNotes,
      NotesSortMode viewSortMode,
      NotesSortMode exportSortMode,
      bool showBookmarks,
      Set<String> enabledTypeColors,
      Set<int> selectedNoteIds});

  @override
  $NotesSortModeCopyWith<$Res> get viewSortMode;
  @override
  $NotesSortModeCopyWith<$Res> get exportSortMode;
}

/// @nodoc
class __$BookNotesStateCopyWithImpl<$Res>
    implements _$BookNotesStateCopyWith<$Res> {
  __$BookNotesStateCopyWithImpl(this._self, this._then);

  final _BookNotesState _self;
  final $Res Function(_BookNotesState) _then;

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? book = null,
    Object? allNotes = null,
    Object? visibleNotes = null,
    Object? viewSortMode = null,
    Object? exportSortMode = null,
    Object? showBookmarks = null,
    Object? enabledTypeColors = null,
    Object? selectedNoteIds = null,
  }) {
    return _then(_BookNotesState(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      allNotes: null == allNotes
          ? _self._allNotes
          : allNotes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
      visibleNotes: null == visibleNotes
          ? _self._visibleNotes
          : visibleNotes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
      viewSortMode: null == viewSortMode
          ? _self.viewSortMode
          : viewSortMode // ignore: cast_nullable_to_non_nullable
              as NotesSortMode,
      exportSortMode: null == exportSortMode
          ? _self.exportSortMode
          : exportSortMode // ignore: cast_nullable_to_non_nullable
              as NotesSortMode,
      showBookmarks: null == showBookmarks
          ? _self.showBookmarks
          : showBookmarks // ignore: cast_nullable_to_non_nullable
              as bool,
      enabledTypeColors: null == enabledTypeColors
          ? _self._enabledTypeColors
          : enabledTypeColors // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedNoteIds: null == selectedNoteIds
          ? _self._selectedNoteIds
          : selectedNoteIds // ignore: cast_nullable_to_non_nullable
              as Set<int>,
    ));
  }

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotesSortModeCopyWith<$Res> get viewSortMode {
    return $NotesSortModeCopyWith<$Res>(_self.viewSortMode, (value) {
      return _then(_self.copyWith(viewSortMode: value));
    });
  }

  /// Create a copy of BookNotesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotesSortModeCopyWith<$Res> get exportSortMode {
    return $NotesSortModeCopyWith<$Res>(_self.exportSortMode, (value) {
      return _then(_self.copyWith(exportSortMode: value));
    });
  }
}

// dart format on
