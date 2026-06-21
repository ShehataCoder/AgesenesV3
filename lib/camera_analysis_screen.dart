import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_painter.dart';
import 'core/app_strings.dart';
import 'core/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'core/image_isolate_processor.dart';
import 'package:provider/provider.dart';
import 'providers/history_provider.dart';

class CameraAnalysisScreen extends StatefulWidget {
  const CameraAnalysisScreen({super.key});

  @override
  State<CameraAnalysisScreen> createState() => _CameraAnalysisScreenState();
}

class _CameraAnalysisScreenState extends State<CameraAnalysisScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  File? _staticImage;
  img.Image? _staticImageDecoded;

  // MLKit & TFLite
  late FaceDetector _faceDetector;
  Interpreter? _interpreter; // Gender Interpreter
  Interpreter? _ageInterpreter; // Age Interpreter
  bool _isBusy = false;
  bool _isFlashOn = false;

  // Decoupled Logic State
  bool _isPredicting = false;
  String _latestLabel = "Detecting...";
  List<FaceBox> _faceBoxes = [];

  // Gender Model Settings
  // Default to 224x224 to match the model training input size.
  // This value is overwritten at runtime by reading the actual TFLite input tensor shape.
  // If model loading fails, inference will still use the correct training size.
  int _inputSize = 224;
  List<int> _outputShape = [1, 1];
  bool _isQuantizedInput = false;
  bool _isQuantizedOutput = false;

  // Age Model Settings
  // Default to 224x224 to match the model training input size.
  int _ageInputSize = 224;
  List<int> _ageOutputShape = [1, 1];
  bool _isAgeQuantizedInput = false;
  bool _isAgeQuantizedOutput = false;

  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _loadModel();
    _initializeCamera();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
      enableTracking: true, // Enabled for decoupled tracking
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      if (Platform.isAndroid) options.addDelegate(XNNPackDelegate());

      // --- Load Gender Model ---
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/gender_model.tflite',
          options: options,
        );
      } catch (e) {
        debugPrint(
          '⚠️ Failed to load gender model with delegates, falling back to CPU: $e',
        );
        _interpreter = await Interpreter.fromAsset(
          'assets/gender_model.tflite',
        );
      }

      final inputTensor = _interpreter!.getInputTensor(0);
      _inputSize = inputTensor.shape[1];
      _isQuantizedInput = inputTensor.type == TensorType.uint8;

      final outputTensor = _interpreter!.getOutputTensor(0);
      _outputShape = outputTensor.shape;
      _isQuantizedOutput = outputTensor.type == TensorType.uint8;

      // --- Load Age Model ---
      try {
        _ageInterpreter = await Interpreter.fromAsset(
          'assets/age_model.tflite',
          options: options,
        );
      } catch (e) {
        debugPrint(
          '⚠️ Failed to load age model with delegates, falling back to CPU: $e',
        );
        _ageInterpreter = await Interpreter.fromAsset(
          'assets/age_model.tflite',
        );
      }

      final ageInputTensor = _ageInterpreter!.getInputTensor(0);
      _ageInputSize = ageInputTensor.shape[1];
      _isAgeQuantizedInput = ageInputTensor.type == TensorType.uint8;

      final ageOutputTensor = _ageInterpreter!.getOutputTensor(0);
      _ageOutputShape = ageOutputTensor.shape;
      _isAgeQuantizedOutput = ageOutputTensor.type == TensorType.uint8;
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _startCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    if (_cameras.isEmpty) return;

    final camera = _cameras[cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      _controller!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Stop camera stream if active
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      setState(() {
        _staticImage = File(pickedFile.path);
        _faceBoxes = []; // Clear previous boxes
        _isBusy = true;
      });

      // Decode image for display and cropping
      final bytes = await _staticImage!.readAsBytes();
      _staticImageDecoded = img.decodeImage(bytes);

      if (_staticImageDecoded != null) {
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        await _processInputImage(
          inputImage,
          originalImage: _staticImageDecoded,
        );
      }

      setState(() {
        _isBusy = false;
      });
    }
  }

  void _clearStaticImage() {
    setState(() {
      _staticImage = null;
      _staticImageDecoded = null;
      _faceBoxes = [];
    });
    // Restart camera
    if (_controller != null && !_controller!.value.isStreamingImages) {
      _controller!.startImageStream(_processCameraImage);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    _interpreter?.close();
    _ageInterpreter?.close();
    super.dispose();
  }

  // --- REFACTORED PROCESS LOOP ---

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _staticImage != null) return;
    _isBusy = true;

    try {
      // 0. Extract Primitives (Sync) - Needed for UI mapping
      final int width = image.width;
      final int height = image.height;
      final int sensorOrientation = _controller!.description.sensorOrientation;
      final CameraLensDirection lensDirection =
          _cameras[_selectedCameraIndex].lensDirection;
      final ImageFormatGroup formatGroup = image.format.group;

      // 1. Prepare InputImage
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      // 2. Detect Faces
      final faces = await _faceDetector.processImage(inputImage);

      // RESET logic: if no faces, reset the label to "Detecting..."
      if (faces.isEmpty) {
        _latestLabel = "Detecting...";
      }

      // 3. Update UI Immediately (Flow A)
      _updateFaceBoxesUI(faces, width, height, sensorOrientation);

      // 4. Trigger AI Prediction if Idle (Flow B)
      if (faces.isNotEmpty && !_isPredicting && _interpreter != null) {
        // Prepare Data for Async Thread - COPY PLANES NOW
        // We MUST copy here because 'image' will be invalidated when we return.
        final List<PlaneData> planesData = image.planes
            .map((p) => PlaneData.fromPlane(p))
            .toList();

        // Fire and Forget (Async)
        _runPredictionPipeline(
          planesData,
          faces,
          width,
          height,
          sensorOrientation,
          lensDirection,
          formatGroup,
        );
      }
    } catch (e) {
      debugPrint("Error in Loop: $e");
    } finally {
      _isBusy = false; // Unlock UI loop
    }
  }

  void _updateFaceBoxesUI(
    List<Face> faces,
    int rawW,
    int rawH,
    int sensorOrientation,
  ) {
    if (!mounted) return;

    final List<FaceBox> newBoxes = [];
    final bool isFront =
        _cameras.isNotEmpty &&
        _cameras[_selectedCameraIndex].lensDirection ==
            CameraLensDirection.front;

    // Swap for UI mapping if needed
    int uprightW = rawW;
    int uprightH = rawH;
    if (Platform.isAndroid &&
        (sensorOrientation == 90 || sensorOrientation == 270)) {
      uprightW = rawH;
      uprightH = rawW;
    }

    for (final face in faces) {
      // Use the global persistent label
      String label = _latestLabel;

      // Note: We are ignoring per-face tracking ID for now to enforce the "Global Latest" rule requested.
      // If we wanted multi-face persistence, we would keep the map logic.
      // But the request specifically asked to use `_latestLabel`.

      final mappedRect = _mapRectToScreen(
        face.boundingBox,
        uprightW,
        uprightH,
        isFrontCamera: isFront,
      );

      newBoxes.add(FaceBox(rect: mappedRect, gender: label));
    }

    setState(() {
      _faceBoxes = newBoxes;
    });
  }

  // Flow B: Heavy AI Task (Async)
  Future<void> _runPredictionPipeline(
    List<PlaneData> planes,
    List<Face> faces,
    int width,
    int height,
    int rotation,
    CameraLensDirection lens,
    ImageFormatGroup format,
  ) async {
    _isPredicting = true;

    try {
      // 1. Compute the correct rotation to pass to the Isolate.
      // MLKit returns bounding boxes relative to the image AFTER applying
      // rotationCompensation (the same value used in _inputImageFromCameraImage).
      // We must pass that same compensation angle to the Isolate so it rotates
      // the raw buffer to the same upright orientation before cropping.
      // Passing the raw sensorOrientation caused a double-transformation bug.
      int isolateRotation = 0;
      if (Platform.isAndroid) {
        var rotationCompensation =
            _orientations[_controller!.value.deviceOrientation] ?? 0;
        if (lens == CameraLensDirection.front) {
          isolateRotation = (rotation + rotationCompensation) % 360;
        } else {
          isolateRotation = (rotation - rotationCompensation + 360) % 360;
        }
      } else if (Platform.isIOS) {
        isolateRotation = rotation;
      }

      // 2. Prepare Isolate Data
      final List<List<int>> faceCoords = faces
          .map(
            (f) => [
              f.boundingBox.left.toInt(),
              f.boundingBox.top.toInt(),
              f.boundingBox.width.toInt(),
              f.boundingBox.height.toInt(),
            ],
          )
          .toList();

      final isolateData = IsolateData(
        planes: planes,
        width: width,
        height: height,
        rotation: isolateRotation,
        lensDirection: lens,
        formatGroup: format,
        faceCoordinates: faceCoords,
        targetWidth: _inputSize,
        targetHeight: _inputSize,
      );

      // 2. Run Isolate (Resize/Crop)
      final List<img.Image> faceCrops = await ImageIsolateProcessor.process(
        isolateData,
      );

      // 3. Run Inference (TFLite)
      final Map<int, String> newLabels = {};

      for (int i = 0; i < faces.length; i++) {
        if (i >= faceCrops.length) break;

        final face = faces[i];
        final crop = faceCrops[i];
        final int? id = face.trackingId;

        // Gender
        String gender = _predictGender(crop);

        // Age
        String age = "";
        if (_ageInterpreter != null) {
          img.Image ageInput = crop;
          if (_ageInputSize != _inputSize) {
            // Use linear (bilinear) interpolation to match the default resize
            // behaviour of cv2.resize / PIL.Image.resize used during training.
            ageInput = img.copyResize(
              crop,
              width: _ageInputSize,
              height: _ageInputSize,
              interpolation: img.Interpolation.linear,
            );
          }
          age = _predictAge(ageInput);
        }

        final label = age.isNotEmpty ? "$gender, $age year" : gender;
        if (i == 0) {
          // We only care about the first/primary face for the global label
          _latestLabel = label;
        }

        if (id != null) {
          newLabels[id] = label;
        }
      }

      // 4. Update UI with Fresh Labels
      if (mounted) {
        setState(() {
          // Trigger rebuild so the Fast Loop picks up the new `_latestLabel`
        });
      }
    } catch (e) {
      debugPrint("AI Error: $e");
    } finally {
      _isPredicting = false;
    }
  }

  Future<List<Map<String, dynamic>>> _processInputImage(
    InputImage inputImage, {
    img.Image? originalImage,
    bool isCameraStream = false,
  }) async {
    final String detectingStr = AppStrings.getText(
      context,
      'detecting',
      listen: false,
    );

    final faces = await _faceDetector.processImage(inputImage);
    final List<Map<String, dynamic>> results = [];

    if (faces.isEmpty) {
      if (mounted) setState(() => _faceBoxes = []);
      return results;
    }

    final List<FaceBox> newBoxes = [];

    for (final face in faces) {
      final rect = face.boundingBox;
      String gender = detectingStr;
      String age = "";

      if (originalImage != null && _interpreter != null) {
        try {
          int left = rect.left.toInt().clamp(0, originalImage.width - 1);
          int top = rect.top.toInt().clamp(0, originalImage.height - 1);
          int width = rect.width.toInt().clamp(1, originalImage.width - left);
          int height = rect.height.toInt().clamp(1, originalImage.height - top);

          final faceCrop = img.copyCrop(
            originalImage,
            x: left,
            y: top,
            width: width,
            height: height,
          );

          // Resize face crop to model input size (224x224).
          // Linear interpolation matches the default cv2/PIL bilinear resize
          // used in the training pipeline, preserving texture fidelity.
          final resizedFaceGender = img.copyResize(
            faceCrop,
            width: _inputSize,
            height: _inputSize,
            interpolation: img.Interpolation.linear,
          );
          gender = _predictGender(resizedFaceGender);

          if (_ageInterpreter != null) {
            // Resize to age model input size (224x224) using linear interpolation.
            final resizedFaceAge = img.copyResize(
              faceCrop,
              width: _ageInputSize,
              height: _ageInputSize,
              interpolation: img.Interpolation.linear,
            );
            age = _predictAge(resizedFaceAge);
          }
        } catch (e) {
          debugPrint("❌ Prediction Logic Error: $e");
          gender = "Error";
        }
      }

      Rect mappedRect = rect;
      if (isCameraStream) {
        final isFrontCamera =
            _cameras.isNotEmpty &&
            _cameras[_selectedCameraIndex].lensDirection ==
                CameraLensDirection.front;

        mappedRect = _mapRectToScreen(
          rect,
          originalImage?.width ?? 1,
          originalImage?.height ?? 1,
          isFrontCamera: isFrontCamera,
        );
      } else {
        mappedRect = _mapRectToScreen(
          rect,
          originalImage?.width ?? 1,
          originalImage?.height ?? 1,
          isStaticImage: true,
        );
      }

      final label = age.isNotEmpty ? "$gender, $age year" : gender;
      newBoxes.add(FaceBox(rect: mappedRect, gender: label));

      results.add({
        'gender': gender,
        'age': age,
        'box': rect, // Store raw rect for sorting if needed
      });
    }

    if (mounted) {
      setState(() {
        _faceBoxes = newBoxes;
      });
    }

    return results;
  }

  // --- HELPERS ---

  String _predictGender(img.Image faceImage) {
    try {
      Object inputBuffer;
      if (_isQuantizedInput) {
        var input = Uint8List(1 * _inputSize * _inputSize * 3);
        var pixelIndex = 0;
        for (var y = 0; y < _inputSize; y++) {
          for (var x = 0; x < _inputSize; x++) {
            final pixel = faceImage.getPixel(x, y);
            input[pixelIndex++] = pixel.r.toInt();
            input[pixelIndex++] = pixel.g.toInt();
            input[pixelIndex++] = pixel.b.toInt();
          }
        }
        inputBuffer = input.reshape([1, _inputSize, _inputSize, 3]);
      } else {
        // Float32 input: normalize pixel values from [0, 255] → [0.0, 1.0].
        // This MUST match the rescale/normalization used during model training
        // (e.g. ImageDataGenerator(rescale=1./255) in Keras, or transforms.ToTensor() in PyTorch).
        var input = Float32List(1 * _inputSize * _inputSize * 3);
        var pixelIndex = 0;
        for (var y = 0; y < _inputSize; y++) {
          for (var x = 0; x < _inputSize; x++) {
            final pixel = faceImage.getPixel(x, y);
            // Gender model normalizes internally — send raw pixels [0, 255]
            input[pixelIndex++] = pixel.r.toDouble();
            input[pixelIndex++] = pixel.g.toDouble();
            input[pixelIndex++] = pixel.b.toDouble();
          }
        }
        inputBuffer = input.reshape([1, _inputSize, _inputSize, 3]);
      }

      int totalOutputSize = _outputShape.reduce((a, b) => a * b);
      var outputBuffer = _isQuantizedOutput
          ? List.filled(totalOutputSize, 0).reshape(_outputShape)
          : List.filled(totalOutputSize, 0.0).reshape(_outputShape);

      _interpreter!.run(inputBuffer, outputBuffer);

      String label = "Unknown";
      String confidence = "";

      if (totalOutputSize == 1) {
        var val = outputBuffer[0][0];
        double prob = _isQuantizedOutput ? (val / 255.0) : val.toDouble();
        // Model outputs: Male=0, Female=1
        // prob > 0.5 → closer to 0 → Male
        label = prob > 0.5 ? "Female" : "Male";
        confidence = prob.toStringAsFixed(2);
      } else if (totalOutputSize >= 2) {
        var val0 = outputBuffer[0][0];
        var val1 = outputBuffer[0][1];
        double prob0 = _isQuantizedOutput ? (val0 / 255.0) : val0.toDouble();
        double prob1 = _isQuantizedOutput ? (val1 / 255.0) : val1.toDouble();
        // Assuming output[1] = Female prob, output[0] = Male prob
        if (prob0 > prob1) {
          label = "Female";
          confidence = prob0.toStringAsFixed(2);
        } else {
          label = "Male";
          confidence = prob1.toStringAsFixed(2);
        }
      }
      return "$label ($confidence)";
    } catch (e) {
      debugPrint("❌ Error in _predictGender: $e");
      return "Error";
    }
  }

  String _predictAge(img.Image faceImage) {
    try {
      Object inputBuffer;
      if (_isAgeQuantizedInput) {
        var input = Uint8List(1 * _ageInputSize * _ageInputSize * 3);
        var pixelIndex = 0;
        for (var y = 0; y < _ageInputSize; y++) {
          for (var x = 0; x < _ageInputSize; x++) {
            final pixel = faceImage.getPixel(x, y);
            input[pixelIndex++] = pixel.r.toInt();
            input[pixelIndex++] = pixel.g.toInt();
            input[pixelIndex++] = pixel.b.toInt();
          }
        }
        inputBuffer = input.reshape([1, _ageInputSize, _ageInputSize, 3]);
      } else {
        // The TFLite model has a Rescaling layer baked in as the first layer.
        // This means the model expects RAW pixel values in [0, 255] as float32.
        // The model handles all normalization internally — do NOT normalize here.
        var input = Float32List(1 * _ageInputSize * _ageInputSize * 3);
        var pixelIndex = 0;
        for (var y = 0; y < _ageInputSize; y++) {
          for (var x = 0; x < _ageInputSize; x++) {
            final pixel = faceImage.getPixel(x, y);
            input[pixelIndex++] = pixel.r.toDouble();
            input[pixelIndex++] = pixel.g.toDouble();
            input[pixelIndex++] = pixel.b.toDouble();
          }
        }
        inputBuffer = input.reshape([1, _ageInputSize, _ageInputSize, 3]);
      }

      int totalOutputSize = _ageOutputShape.reduce((a, b) => a * b);
      var outputBuffer = _isAgeQuantizedOutput
          ? List.filled(totalOutputSize, 0).reshape(_ageOutputShape)
          : List.filled(totalOutputSize, 0.0).reshape(_ageOutputShape);

      _ageInterpreter!.run(inputBuffer, outputBuffer);

      if (totalOutputSize == 1) {
        var val = outputBuffer[0][0];
        // Age model is a regression model that outputs the actual age directly
        // (e.g. 25.5 means 25.5 years old). No scaling needed.
        double age = _isAgeQuantizedOutput ? val.toDouble() : val.toDouble();
        return age.toStringAsFixed(1);
      } else {
        List<dynamic> probs = outputBuffer[0];
        int maxIndex = 0;
        num maxProb = -1;
        for (int i = 0; i < probs.length; i++) {
          num prob = probs[i];
          if (prob > maxProb) {
            maxProb = prob;
            maxIndex = i;
          }
        }
        return maxIndex.toString();
      }
    } catch (e) {
      debugPrint("❌ Error in _predictAge: $e");
      return "";
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation = InputImageRotation.rotation0deg;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation =
          InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    } else if (Platform.isIOS) {
      rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    }

    if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
      if (image.planes.length < 3) return null;

      final int width = image.width;
      final int height = image.height;
      final Plane yPlane = image.planes[0];
      final Plane uPlane = image.planes[1];
      final Plane vPlane = image.planes[2];
      final Uint8List yBuffer = yPlane.bytes;
      final Uint8List uBuffer = uPlane.bytes;
      final Uint8List vBuffer = vPlane.bytes;

      final int numPixels = width * height;
      final List<int> nv21 = List.filled(numPixels + (numPixels >> 1), 0);

      int idY = 0;
      int idUV = numPixels;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      for (int y = 0; y < height; y++) {
        final int yOffset = y * yPlane.bytesPerRow;
        for (int x = 0; x < width; x++) {
          nv21[idY++] = yBuffer[yOffset + x];
        }
      }

      for (int y = 0; y < height ~/ 2; y++) {
        final int uvOffset = y * uvRowStride;
        for (int x = 0; x < width ~/ 2; x++) {
          final int uvIndex = uvOffset + (x * uvPixelStride);
          final byteV = vBuffer[uvIndex];
          final byteU = uBuffer[uvIndex];
          nv21[idUV++] = byteV;
          nv21[idUV++] = byteU;
        }
      }

      final bytes = Uint8List.fromList(nv21);
      final metadata = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    }

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final bytes = _concatenatePlanes(image.planes);
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Rect _mapRectToScreen(
    Rect rect,
    int imageWidth,
    int imageHeight, {
    bool isFrontCamera = false,
    bool isStaticImage = false,
  }) {
    if (!mounted) return rect;
    final Size screenSize = MediaQuery.of(context).size;

    // 1. Calculate Scale
    double scaleX = screenSize.width / imageWidth;
    double scaleY = screenSize.height / imageHeight;
    double scale = isStaticImage
        ? math.min(scaleX, scaleY)
        : math.max(scaleX, scaleY);

    double scaledImageWidth = imageWidth * scale;
    double scaledImageHeight = imageHeight * scale;

    double offsetX = (screenSize.width - scaledImageWidth) / 2;
    double offsetY = (screenSize.height - scaledImageHeight) / 2;

    double left = rect.left * scale;
    double top = rect.top * scale;
    double width = rect.width * scale;
    double height = rect.height * scale;
    double right = left + width;
    double bottom = top + height;

    if (isFrontCamera) {
      double originalLeft = left;
      left = scaledImageWidth - right;
      right = scaledImageWidth - originalLeft;
    }

    return Rect.fromLTRB(
      left + offsetX,
      top + offsetY,
      right + offsetX,
      bottom + offsetY,
    );
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // 1. Prioritize User Action
    setState(() => _isBusy = true);

    try {
      // 2. Stop Stream
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }

      // 3. Safety Delay
      await Future.delayed(const Duration(milliseconds: 50));

      // 4. Capture
      final XFile file = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final String fileName = 'img_$timestamp.jpg';
      final String filePath = path.join(directory.path, fileName);
      await file.saveTo(filePath);

      // 5. Freeze UI (Display Captured Image Immediately)
      setState(() {
        _staticImage = File(filePath);
      });

      final bytes = await File(filePath).readAsBytes();
      final img.Image? capturedImage = img.decodeImage(bytes);

      if (capturedImage != null) {
        // 6. Run Prediction on Static Image (Updates UI & Returns Data)
        final inputImage = InputImage.fromFilePath(filePath);
        final results = await _processInputImage(
          inputImage,
          originalImage: capturedImage,
        );

        String gender = "Unknown";
        String age = "Unknown";

        // 7. Pick Best Face for Database (Largest Box)
        if (results.isNotEmpty) {
          // Sort by area desc
          results.sort((a, b) {
            final Rect ra = a['box'];
            final Rect rb = b['box'];
            return (rb.width * rb.height).compareTo(ra.width * ra.height);
          });

          gender = results.first['gender'];
          age = results.first['age'];
        }

        // 8. Save to DB
        await DatabaseHelper.instance.insertPrediction({
          'image_path': filePath,
          'gender': gender,
          'age': age,
          'timestamp': DateTime.now().toString(),
        });

        if (mounted) {
          // Refresh History
          Provider.of<HistoryProvider>(
            context,
            listen: false,
          ).loadPredictions();

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved: $gender, $age')));
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_staticImage != null)
            Image.file(_staticImage!, fit: BoxFit.contain)
          else if (_controller != null && _controller!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned.fill(child: CustomPaint(painter: FacePainter(_faceBoxes))),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),

                      if (_staticImage != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _clearStaticImage,
                        )
                      else
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: _isFlashOn
                                ? const Color(0xFF2962FF)
                                : Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_staticImage == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _pickImage,
                    ),
                    GestureDetector(
                      onTap: _onCapturePressed,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
