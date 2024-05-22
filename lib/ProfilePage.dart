import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'ReviewPage.dart';
import 'ListPage.dart';
import 'Widgets.dart';
import 'globals.dart';
import 'globals.dart' as global;
import 'package:http/http.dart' as http;
import 'dart:io';

import 'main.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _tabViewHeight = 532; // Initial height, adjust as needed
  final GlobalKey _keyTab1 = GlobalKey();
  final GlobalKey _keyTab2 = GlobalKey();
  final GlobalKey _keyTab3 = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_setTabHeight);
  }

  void _setTabHeight() {
    if (_tabController.indexIsChanging) return;

    GlobalKey currentKey;
    switch (_tabController.index) {
      case 0:
        currentKey = _keyTab1;
        break;
      case 1:
        currentKey = _keyTab2;
        break;
      case 2:
        currentKey = _keyTab3;
        break;
      default:
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox box =
          currentKey.currentContext?.findRenderObject() as RenderBox;
      final newHeight = box.size.height;
      if (_tabViewHeight != newHeight) {
        setState(() => _tabViewHeight = newHeight);
      }
    });
  }

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_user_info.php?userid=${userData.userId}'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user information');
    }
  }

  final picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    // Select an image from the gallery
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      FormData formData = FormData.fromMap({
        'userid': userData.userId,
        'access_token': userData.accesstoken,
        'profile_pic': await MultipartFile.fromFile(imageFile.path),
      });

      Dio dio = Dio();

      try {
        var response = await dio.post(
            'https://app.medleyapp.co.uk/update_user_data.php',
            data: formData);

        if (response.statusCode == 200) {
          print('${response.data}');
        } else {
          print(
              'Failed to upload profile picture. Status code: ${response.statusCode}');
        }
      } on DioError catch (e) {
        print('Dio error: ${e.message}');
      } catch (e) {
        print('Unknown error: $e');
      }
    } else {
      print('No image selected');
    }
  }

  void refreshLibrary() {
    setState(() {
      // Perform any necessary updates here
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child:
                      CircularProgressIndicator()); // Loading indicator while fetching data
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(
                  child: Text('No data available')); // Handle case with no data
            } else {
              final userData = snapshot.data;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 15,
                            ),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      height: 150.0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              _getImage(ImageSource.camera);
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(Icons.camera_alt),
                                            label: Text('Take a photo'),
                                            style: ButtonStyle(
                                                iconColor: MaterialStateProperty
                                                    .all<Color>(Colors.purple),
                                                foregroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.purple)),
                                          ),
                                          SizedBox(height: 10.0),
                                          TextButton.icon(
                                            onPressed: () {
                                              _getImage(ImageSource.gallery);
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(Icons.photo_library),
                                            label: Text('Choose from gallery'),
                                            style: ButtonStyle(
                                                iconColor: MaterialStateProperty
                                                    .all<Color>(Colors.purple),
                                                foregroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.purple)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(
                                      userData?['profile_picture']),
                                ),
                              ),
                            ),
                            SizedBox(width: 35.0),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfilePage()));
                                },
                                child: Text('Edit Profile'),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['display_name'],
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${userData?['username']}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              userData?['bio'], // Replace with userData['bio']
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                              "Followers",
                              "250",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          _buildStatItem(
                              "Following",
                              "300",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          _buildStatItem(
                              "Reviews",
                              "50",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          // Add more stat items as needed
                        ],
                      ),
                    ),
                    Divider(),
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: "Library"),
                        Tab(text: "Reviews"),
                        Tab(text: "Lists"),
                      ],
                    ),
                    Container(
                      height: _tabViewHeight, // Set a height for the TabBarView
                      child: TabBarView(controller: _tabController, children: [
                        Column(
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Visibility(
                              visible: global.notReviewedIds.isNotEmpty ||
                                  global.listenedIds.isNotEmpty ||
                                  global.backlogIds.isNotEmpty,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: RecentsBox(
                                  username: global.userData.displayName,
                                  userId: userData!['id'],
                                  refreshCall: refreshLibrary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: FavouritesBox(
                                username: 'testuser',
                                userid: '3',
                                refreshCall: refreshLibrary,
                              ),
                            ),
                            Divider()
                          ],
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Text(
                                    "${global.userData.displayName}'s Reviews",
                                    style: TextStyle(fontSize: 20),
                                  )),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                child: UserReviewsList(
                                  userName: global.userData.username,
                                  userId: global.userData.userId,
                                ),
                              ),
                            ]),
                        Container(
                            child: ListWidget(
                          userId: global.userData.userId,
                        )),
                      ]),
                    ),
                    UserComments(
                      userid: '',
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String count, Widget page) {
    return GestureDetector(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  File? imageFile;

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_user_info.php?userid=${userData.userId}'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user information');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    // Select an image from the gallery
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      FormData formData = FormData.fromMap({
        'userid': userData.userId,
        'access_token': userData.accesstoken,
        'profile_pic': await MultipartFile.fromFile(imageFile.path),
      });

      Dio dio = Dio();

      try {
        var response = await dio.post(
            'https://app.medleyapp.co.uk/update_user_data.php',
            data: formData);

        if (response.statusCode == 200) {
          print('${response.data}');
        } else {
          print(
              'Failed to upload profile picture. Status code: ${response.statusCode}');
        }
      } on DioError catch (e) {
        print('Dio error: ${e.message}');
      } catch (e) {
        print('Unknown error: $e');
      }
    } else {
      print('No image selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit Profile"),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            } else {
              final userinfo = snapshot.data;
              displayNameController.text = userinfo?['display_name'];
              usernameController.text = userinfo?['username'];
              bioController.text = userinfo?['bio'];

              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              height: 150.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      _getImage(ImageSource.camera);
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.camera_alt),
                                    label: Text('Take a photo'),
                                    style: ButtonStyle(
                                        iconColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.purple),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.purple)),
                                  ),
                                  SizedBox(height: 10.0),
                                  TextButton.icon(
                                    onPressed: () {
                                      _getImage(ImageSource.gallery);
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.photo_library),
                                    label: Text('Choose from gallery'),
                                    style: ButtonStyle(
                                        iconColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.purple),
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.purple)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            NetworkImage(userinfo?['profile_picture']),
                      ),
                    ),
                    SizedBox(height: 20),
                    buildTextField("Display Name", displayNameController),
                    buildTextField("Username", usernameController),
                    buildTextField("Bio", bioController),
                    ElevatedButton(
                      onPressed: () async {
                        var response = await http.post(
                            Uri.parse(
                                'https://app.medleyapp.co.uk/update_user_data.php'),
                            body: {
                              'access_token': userData.accesstoken,
                              'userid': userData.userId,
                              'new_username': usernameController.text,
                              'new_display_name': displayNameController.text,
                              'bio': bioController.text
                            });
                        if (response.body == 'Successfully Changed User Data') {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Saved Changes'),
                            backgroundColor: Colors.green,
                          ));
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Save Changes'),
                    ),
                    // Add other widgets as needed
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class UserPage extends StatefulWidget {
  final String userId; // Add a parameter to specify the user to display
  UserPage({required this.userId});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _tabViewHeight = 532; // Initial height, adjust as needed
  final GlobalKey _keyTab1 = GlobalKey();
  final GlobalKey _keyTab2 = GlobalKey();
  final GlobalKey _keyTab3 = GlobalKey();
  var userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_setTabHeight);
  }

  void refreshLibrary() {
    setState(() {
      // Perform any necessary updates here
    });
  }

  void _setTabHeight() {
    if (_tabController.indexIsChanging) return;

    GlobalKey currentKey;
    switch (_tabController.index) {
      case 0:
        currentKey = _keyTab1;
        break;
      case 1:
        currentKey = _keyTab2;
        break;
      case 2:
        currentKey = _keyTab3;
        break;
      default:
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox box =
          currentKey.currentContext?.findRenderObject() as RenderBox;
      final newHeight = box.size.height;
      if (_tabViewHeight != newHeight) {
        setState(() => _tabViewHeight = newHeight);
      }
    });
  }

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_user_info.php?userid=${widget.userId}'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user information');
    }
  }

  // Rest of the code remains the same

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: Text(
          userData?['username'] ?? '',
        )),
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child:
                      CircularProgressIndicator()); // Loading indicator while fetching data
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(
                  child: Text('No data available')); // Handle case with no data
            } else {
              userData = snapshot.data;
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 15,
                            ),
                            GestureDetector(
                              onTap: () {
                                // Handle profile picture editing
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(
                                      userData?['profile_picture']),
                                ),
                              ),
                            ),
                            SizedBox(width: 35.0),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Handle Edit Profile button press
                                },
                                child: Text('Follow'),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['display_name'],
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${userData?['username']}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              userData?['bio'], // Replace with userData['bio']
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                              "Followers",
                              "250",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          _buildStatItem(
                              "Following",
                              "300",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          _buildStatItem(
                              "Reviews",
                              "50",
                              ReviewListPage(
                                displayName: 'Test',
                                userid: '',
                              )),
                          // Add more stat items as needed
                        ],
                      ),
                    ),
                    Divider(),
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: "Library"),
                        Tab(text: "Reviews"),
                        Tab(text: "Lists"),
                      ],
                    ),
                    Container(
                      height: _tabViewHeight, // Set a height for the TabBarView
                      child: TabBarView(controller: _tabController, children: [
                        Column(
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            Visibility(
                              visible: global.notReviewedIds.isNotEmpty ||
                                  global.listenedIds.isNotEmpty ||
                                  global.backlogIds.isNotEmpty,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: RecentsBox(
                                  username: global.userData.displayName,
                                  userId: userData!['id'],
                                  refreshCall: refreshLibrary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.0),
                              child: FavouritesBox(
                                username: 'testuser',
                                userid: '3',
                                refreshCall: refreshLibrary,
                              ),
                            ),
                            Divider()
                          ],
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0),
                                  child: Text(
                                    "${global.userData.displayName}'s Reviews",
                                    style: TextStyle(fontSize: 20),
                                  )),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                child: UserReviewsList(
                                  userName: global.userData.username,
                                  userId: global.userData.userId,
                                ),
                              ),
                            ]),
                        Container(
                            child: ListWidget(
                          userId: global.userData.userId,
                        )),
                      ]),
                    ),
                    UserComments(
                      userid: '',
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String count, Widget page) {
    return GestureDetector(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}

class TagSelectionPage extends StatefulWidget {
  final String userId; // Pass the user ID to the page

  TagSelectionPage({required this.userId});

  @override
  _TagSelectionPageState createState() => _TagSelectionPageState();
}

class _TagSelectionPageState extends State<TagSelectionPage> {
  List<Map<String, dynamic>> originalSelectedTags = [];
  List<Map<String, dynamic>> originalUnselectedTags = [];
  List<Map<String, dynamic>> selectedTags = [];
  List<Map<String, dynamic>> unselectedTags = [];
  bool isDataChanged = false;

  @override
  void initState() {
    super.initState();
    fetchTagsFromServer();
  }

  Future<void> fetchTagsFromServer() async {
    final response = await http.get(
      Uri.parse(
          'https://app.medleyapp.co.uk/get_tags.php?userId=${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      setState(() {
        originalSelectedTags = List<Map<String, dynamic>>.from(
            data['selectedTags']
                .map((tag) => {'id': tag['tag_id'], 'name': tag['tag_name']}));
        originalUnselectedTags = List<Map<String, dynamic>>.from(
            data['unselectedTags']
                .map((tag) => {'id': tag['tag_id'], 'name': tag['tag_name']}));
        selectedTags = List<Map<String, dynamic>>.from(originalSelectedTags);
        unselectedTags =
            List<Map<String, dynamic>>.from(originalUnselectedTags);
      });
    } else {
      // Handle error when fetching tags
      print('Failed to fetch tags');
    }
  }

  Future<void> saveSelectedTags() async {
    final response = await http.post(
      Uri.parse('https://app.medleyapp.co.uk/change_user_tags.php'),
      body: {
        'userId': widget.userId,
        'tags': json.encode(selectedTags.map((tag) => tag['id']).toList()),
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['message'] == 'Tags updated successfully') {
        print('Tags updated successfully');
        setState(() {
          originalSelectedTags = List<Map<String, dynamic>>.from(selectedTags);
          originalUnselectedTags =
              List<Map<String, dynamic>>.from(unselectedTags);
          isDataChanged = false;
        });
      } else {
        print('Failed to update tags');
      }
    } else {
      // Handle error when updating tags
      print('Failed to update tags');
    }
  }

  Future<bool> _onWillPop() async {
    if (!isDataChanged) {
      return true;
    }

    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Unsaved Changes'),
            content:
                Text('You have unsaved changes. Do you want to save them?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () {
                  saveSelectedTags();
                  Navigator.of(context).pop(true);
                },
                child: Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select Your Favorite Genres'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildTagSegment('Selected Tags', selectedTags, true),
                _buildTagSegment('Unselected Tags', unselectedTags, false),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            saveSelectedTags();
            Future.delayed(Duration(milliseconds: 100));
            Navigator.pop(context);
          },
          child: Icon(Icons.save),
        ),
      ),
    );
  }

  Widget _buildTagSegment(
    String title,
    List<Map<String, dynamic>> tags,
    bool isSelectedSegment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(tags.length, (index) {
            final tag = tags[index];
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isSelectedSegment) {
                    selectedTags.remove(tag);
                    unselectedTags.add(tag);
                  } else {
                    unselectedTags.remove(tag);
                    selectedTags.add(tag);
                  }
                  isDataChanged = true;
                });
              },
              style: ButtonStyle(
                backgroundColor: isSelectedSegment
                    ? MaterialStateProperty.all<Color>(Colors.blue)
                    : MaterialStateProperty.all<Color>(Colors.grey),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              child: Text(
                tag['name'],
                style: TextStyle(
                  color: isSelectedSegment ? Colors.white : Colors.black,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class RegisterCompletionPage extends StatefulWidget {
  @override
  _RegisterCompletionPageState createState() => _RegisterCompletionPageState();
}

class _RegisterCompletionPageState extends State<RegisterCompletionPage> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  File? imageFile;

  Future<void> _getImage(ImageSource source) async {
    // Select an image from the gallery
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });

      FormData formData = FormData.fromMap({
        'userid': userData.userId,
        'access_token': userData.accesstoken,
        'profile_pic': await MultipartFile.fromFile(imageFile!.path),
      });

      Dio dio = Dio();

      try {
        var response = await dio.post(
            'https://app.medleyapp.co.uk/update_user_data.php',
            data: formData);

        if (response.statusCode == 200) {
          print('${response.data}');
        } else {
          print(
              'Failed to upload profile picture. Status code: ${response.statusCode}');
        }
      } on DioError catch (e) {
        print('Dio error: ${e.message}');
      } catch (e) {
        print('Unknown error: $e');
      }
    } else {
      print('No image selected');
    }
  }

  Future<void> _completeRegistration() async {
    var response = await Dio().post(
      'https://app.medleyapp.co.uk/complete_registration.php',
      data: {
        'access_token': userData.accesstoken,
        'userid': userData.userId,
        'username': usernameController.text,
        'display_name': displayNameController.text,
        'bio': bioController.text,
      },
    );

    if (response.statusCode == 200) {
      print('Registration completed successfully.');
      Navigator.pushReplacementNamed(
          context, '/'); // Navigate back after successful registration
    } else {
      print(
          'Failed to complete registration. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complete Your Profile"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        height: 150.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _getImage(ImageSource.camera);
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.camera_alt),
                              label: Text('Take a photo'),
                            ),
                            SizedBox(height: 10.0),
                            TextButton.icon(
                              onPressed: () {
                                _getImage(ImageSource.gallery);
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.photo_library),
                              label: Text('Choose from gallery'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile!) as ImageProvider
                      : AssetImage('') as ImageProvider,
                )),
            SizedBox(height: 20),
            buildTextField("Display Name", displayNameController),
            buildTextField("Bio", bioController),
            ElevatedButton(
              onPressed: () async {
                var response = await http.post(
                    Uri.parse(
                        'https://app.medleyapp.co.uk/update_user_data.php'),
                    body: {
                      'access_token': userData.accesstoken,
                      'userid': userData.userId,
                      'new_display_name': displayNameController.text,
                      'bio': bioController.text
                    });
                if (response.body == 'Successfully Changed User Data') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved Changes'),
                    backgroundColor: Colors.green,
                  ));
                  Future.delayed(Duration(milliseconds: 100));
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => MainScreen()));
                }
              },
              child: Text('Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
