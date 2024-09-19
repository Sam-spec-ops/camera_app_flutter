// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late CameraController cameraController;
  late Future<void> cameraValue;
  List<File> imagesList = [];
  bool isFlashOn = false;
  bool isRearCamera = true;

  @override
  void initState() {
    startCamera(0);
    super.initState();
  }

  Future<File> saveImage(XFile image) async {
    final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('$downloadPath/$fileName');
    try {
      await file.writeAsBytes(await image.readAsBytes());
    } catch (_) {}
    return file;
  }

  void startCamera(int camera) {
    cameraController = CameraController(
        widget.cameras[camera], ResolutionPreset.high,
        enableAudio: false);
    cameraValue = cameraController.initialize();
  }

  void takePicture() async {
    XFile? image;
    if (cameraController.value.isTakingPicture ||
        !cameraController.value.isInitialized) {
      return;
    }
    if (isFlashOn == false) {
      await cameraController.setFlashMode(FlashMode.off);
    } else {
      await cameraController.setFlashMode(FlashMode.torch);
    }
    image = await cameraController.takePicture();
    if (cameraController.value.flashMode == FlashMode.torch) {
      setState(() {
        cameraController.setFlashMode(FlashMode.off);
      });
    }
    final file = await saveImage(image);
    setState(() {
      imagesList.add(file);
    });
    MediaScanner.loadMedia(path: file.path);
  }

  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(225, 225, 225, 7),
          shape: CircleBorder(),
          onPressed: takePicture,
          child: Icon(
            Icons.camera_alt,
            size: 40,
            color: Colors.black87,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Stack(children: [
          FutureBuilder(
              future: cameraValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SizedBox(
                    width: size.width,
                    height: size.height,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                          width: 100, child: CameraPreview(cameraController)),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }),
          SafeArea(
            child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 5, top: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              isFlashOn = !isFlashOn;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(50, 0, 0, 0),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                                padding: EdgeInsets.all(10),
                                child: isFlashOn
                                    ? Icon(Icons.flash_on,
                                        color: Colors.white, size: 30)
                                    : Icon(Icons.flash_off,
                                        color: Colors.white, size: 30)),
                          )),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isRearCamera = !isRearCamera;
                          });
                          isRearCamera ? startCamera(0) : startCamera(1);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(50, 0, 0, 0),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: isRearCamera
                                  ? Icon(Icons.camera_rear,
                                      color: Colors.white, size: 30)
                                  : Icon(Icons.camera_front,
                                      color: Colors.white, size: 30)),
                        ),
                      ),
                    ],
                  ),
                )),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: EdgeInsets.only(left: 7, bottom: 75),
                  child: Container(
                    height: 100,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: imagesList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                            padding: EdgeInsets.all(2),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image(
                                    height: 100,
                                    width: 100,
                                    opacity: const AlwaysStoppedAnimation(07),
                                    image: FileImage(File(imagesList[index].path)),
                                    fit: BoxFit.cover)));
                      },
                    ),
                  ),
                ),
              )
            ]),
          ),
        ]));
  }
}
