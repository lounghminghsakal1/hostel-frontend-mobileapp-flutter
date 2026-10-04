import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../model/room_model.dart';
import '../providers/rooms_providers.dart';

/// Opens the create form, or the edit form when [room] is given. Resolves to
/// `true` once the room was saved.
Future<bool> showRoomFormSheet(BuildContext context, {RoomModel? room}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RoomFormSheet(room: room),
  );
  return saved ?? false;
}

class _RoomFormSheet extends ConsumerStatefulWidget {
  const _RoomFormSheet({this.room});

  final RoomModel? room;

  @override
  ConsumerState<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends ConsumerState<_RoomFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _roomNumberController = TextEditingController(text: widget.room?.roomNumber);
  late final _capacityController = TextEditingController(text: widget.room?.capacity?.toString());
  bool _isSaving = false;

  /// Shown above the save button; a SnackBar would sit behind the sheet.
  String? _error;

  bool get _isEditing => widget.room != null;

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    final roomNumber = _roomNumberController.text.trim();
    final capacity = int.parse(_capacityController.text.trim());
    final repository = ref.read(roomsRepositoryProvider);
    final room = widget.room;

    // Only send the fields that actually changed.
    final changedRoomNumber = room != null && roomNumber == room.roomNumber ? null : roomNumber;
    final changedCapacity = room != null && capacity == room.capacity ? null : capacity;
    if (room != null && changedRoomNumber == null && changedCapacity == null) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (room == null) {
        await repository.createRoom(roomNumber: roomNumber, capacity: capacity);
      } else {
        await repository.updateRoom(id: room.id, roomNumber: changedRoomNumber, capacity: changedCapacity);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  static String? _capacity(String? value) {
    final capacity = int.tryParse(value?.trim() ?? '');
    return (capacity == null || capacity <= 0) ? 'Enter a number greater than 0' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.navyAlpha(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isEditing ? 'Edit Room' : 'Create Room',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Room number',
                icon: Icons.meeting_room_outlined,
                controller: _roomNumberController,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Capacity',
                icon: Icons.bed_outlined,
                keyboardType: TextInputType.number,
                controller: _capacityController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                validator: _capacity,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: _isEditing ? 'Save changes' : 'Create room',
                icon: _isEditing ? Icons.check_rounded : Icons.add_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
