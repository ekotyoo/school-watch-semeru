import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:school_watch_semeru/features/report/presentation/models/location_pick_nav_arg.dart';
import 'package:school_watch_semeru/features/school/presentation/models/floor_plan_ui_model.dart';

import '../extensions/latlng_extenstion.dart';
import '../../../../../common/routing/routes.dart';
import '../../../../../common/widgets/sw_dropdown.dart';
import '../../models/additional_info_input_wrapper.dart';
import '../../models/location_pick_input.dart';
import '../post_report_controller.dart';
import '../../../../../common/widgets/sw_text_field.dart';
import '../../../../../common/constants/constant.dart';
import '../../../../../common/widgets/title_with_caption.dart';
import '../post_report_state.dart';

class ReportInfoForm extends ConsumerStatefulWidget {
  const ReportInfoForm({super.key, this.descriptionController});

  final TextEditingController? descriptionController;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReportInfoFormState();
}

class _ReportInfoFormState extends ConsumerState<ReportInfoForm> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(postReportControllerProvider.notifier).initReportInfoForm());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postReportControllerProvider);
    const loadingWidget = Center(child: CircularProgressIndicator());

    return Column(
      children: [
        const TitleWithCaption(
          title: SWStrings.labelCompleteReport,
          caption: SWStrings.dummyText,
        ),
        const SizedBox(height: SWSizes.s16),
        Expanded(
          child: state.infoFormLoading ? loadingWidget : ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ..._buildFormInputFields(context, state),
              const Divider(),
              ImagePickerInput(),
            ],
          ),
        ),
      ],
    );
  }

  _buildFormInputFields(BuildContext context, PostReportState state) {
    return [
      SWTextField(
        controller: widget.descriptionController,
        hint: SWStrings.labelDescription,
        maxLines: 5,
        errorText: state.descriptionInput.isPure
            ? null
            : state.descriptionInput.error?.getErrorMessage(),
        action: TextInputAction.done,
        onChanged: (value) => ref
            .read(postReportControllerProvider.notifier)
            .onDescriptionChange(value),
      ),
      const SizedBox(height: SWSizes.s16),
      SWDropdown(
        hint: SWStrings.labelCategory,
        errorText: state.categoryInput.isPure
            ? null
            : state.categoryInput.error?.getErrorMessage(),
        onChanged: (value) => ref
            .read(postReportControllerProvider.notifier)
            .onCategoryChange(value),
        value: state.categoryInput.value,
        items: state.categories
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.label),
                ))
            .toList(),
      ),
      const SizedBox(height: SWSizes.s16),
      _PickLocationButton(
        locationInput: state.locationInput,
        onTap: () async {
          final selectedLocation = state.locationInput.value?.toLatLng();
          final floorPlan = FloorPlanUiModel.fromDomain(state.selectedSchoolData!.floorPlan);

          final position = await context.pushNamed(Routes.locationPicker,
              extra: LocationPickNavArg(selectedPosition: selectedLocation, floorPlan: floorPlan)) as LatLng?;
          ref
              .read(postReportControllerProvider.notifier)
              .onLocationChange(position);
        },
      ),
      const Divider(height: SWSizes.s16),
      for (var i = 0; i < state.additionalInfoInputs.length; i++) ...[
        _AdditionalInfoTextField(
          key: state.additionalInfoInputs[i].key,
          input: state.additionalInfoInputs[i],
          onLabelChanged: (value) {
            ref
                .read(postReportControllerProvider.notifier)
                .onLabelChange(i, value);
          },
          onInformationChanged: (value) {
            ref
                .read(postReportControllerProvider.notifier)
                .onInformationChange(i, value);
          },
          onDelete: () => ref
              .read(postReportControllerProvider.notifier)
              .removeAdditionalInfo(i),
        ),
        const SizedBox(height: SWSizes.s8),
      ],
      const SizedBox(height: SWSizes.s8),
      if (state.additionalInfoInputs.length < kMaxAdditionalInfo)
        TextButton(
          onPressed: () => ref
              .read(postReportControllerProvider.notifier)
              .addAdditionalInfo(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(SWStrings.labelAddAdditionalInfo),
              Icon(Icons.add),
            ],
          ),
        ),
    ];
  }
}

class ImagePickerInput extends ConsumerWidget {
  ImagePickerInput({Key? key, this.errorText}) : super(key: key);

  final _imagePicker = ImagePicker();
  final String? errorText;

  void _pickImageFromGallery(WidgetRef ref) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      ref.read(postReportControllerProvider.notifier).onImagesSelected(images);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _pickImageFromCamera(WidgetRef ref) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (image != null) {
        ref
            .read(postReportControllerProvider.notifier)
            .onImagesSelected([image]);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _buildImageList(List<XFile> images, WidgetRef ref) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) => ImageCard(
        path: images[index].path,
        onDelete: () => ref
            .read(postReportControllerProvider.notifier)
            .onImageDeleted(images[index]),
      ),
      separatorBuilder: (context, index) => const SizedBox(width: SWSizes.s8),
      itemCount: images.length,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postReportControllerProvider);
    final images = state.imageInput.value;

    final emptyImagePlaceholder = DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(SWSizes.s8),
      dashPattern: const [5, 4],
      strokeWidth: 1.5,
      strokeCap: StrokeCap.round,
      color: kColorNeutral200,
      child: SizedBox(
        height: SWSizes.s80,
        child: Center(
          child: Text(
            SWStrings.descNoImagePicked,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: kColorNeutral200),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SWSizes.s80,
          child: images.isNotEmpty
              ? _buildImageList(images, ref)
              : emptyImagePlaceholder,
        ),
        const SizedBox(height: SWSizes.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _pickImageFromCamera(ref),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: kColorNeutral80,
              ),
            ),
            const SizedBox(width: SWSizes.s8),
            GestureDetector(
              onTap: () => _pickImageFromGallery(ref),
              child: const Icon(
                Icons.image,
                color: kColorNeutral80,
              ),
            )
          ],
        ),
        if (!state.imageInput.isPure && state.imageInput.error != null) ...[
          const SizedBox(height: SWSizes.s4),
          Text(
            state.imageInput.error!.getErrorMessage(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: SWSizes.s4),
        ]
      ],
    );
  }
}

class ImageCard extends StatelessWidget {
  const ImageCard({Key? key, required this.path, this.onDelete})
      : super(key: key);

  final String path;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: SWSizes.s80,
          width: SWSizes.s80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SWSizes.s8),
            child: Image.file(
              key: ValueKey(path),
              File(path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: SWSizes.s4,
          right: SWSizes.s4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(SWSizes.s2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SWSizes.s8),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: const Icon(
                Icons.delete_outlined,
                size: 18,
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _AdditionalInfoTextField extends StatefulWidget {
  const _AdditionalInfoTextField({
    Key? key,
    required this.input,
    this.onDelete,
    this.onLabelChanged,
    this.onInformationChanged,
  }) : super(key: key);

  final AdditionalInfoInputWrapper input;
  final VoidCallback? onDelete;
  final Function(String)? onLabelChanged;
  final Function(String)? onInformationChanged;

  @override
  State<_AdditionalInfoTextField> createState() =>
      _AdditionalInfoTextFieldState();
}

class _AdditionalInfoTextFieldState extends State<_AdditionalInfoTextField> {
  late TextEditingController _labelController;
  late TextEditingController _informationController;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.input.labelInput.value);
    _informationController =
        TextEditingController(text: widget.input.informationInput.value);
  }

  @override
  void dispose() {
    super.dispose();
    _labelController.dispose();
    _informationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SWTextField(
            controller: _labelController,
            hint: SWStrings.labelLabel,
            onChanged: widget.onLabelChanged,
            errorText: widget.input.labelInput.isPure
                ? null
                : widget.input.labelInput.error?.getErrorMessage(),
          ),
        ),
        const SizedBox(width: SWSizes.s16),
        Expanded(
          child: SWTextField(
            controller: _informationController,
            hint: SWStrings.labelInformation,
            onChanged: widget.onInformationChanged,
            errorText: widget.input.informationInput.isPure
                ? null
                : widget.input.informationInput.error?.getErrorMessage(),
          ),
        ),
        const SizedBox(width: SWSizes.s8),
        Padding(
          padding: const EdgeInsets.only(top: 28 - (24 / 2)),
          child: GestureDetector(
            onTap: widget.onDelete,
            child: const Icon(
              Icons.close,
              color: kColorNeutral100,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickLocationButton extends StatelessWidget {
  const _PickLocationButton({Key? key, required this.locationInput, this.onTap})
      : super(key: key);

  final LocationPickInput locationInput;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(kColorNeutral100),
              backgroundColor: MaterialStateProperty.all(kColorPrimary50)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locationInput.value == null ? SWStrings.labelLocation : '${locationInput.value?.latitude}, ${locationInput.value?.longitude}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Icon(Icons.pin_drop_outlined),
            ],
          ),
        ),
        if (!locationInput.isPure &&
            locationInput.error?.getErrorMessage() != null) ...[
          const SizedBox(height: SWSizes.s4),
          Text(
            locationInput.error!.getErrorMessage(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: SWSizes.s4),
        ]
      ],
    );
  }
}
