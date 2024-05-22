import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart';
import 'Widgets.dart';

class ListButton extends StatelessWidget {
  final String listTitle;
  final String listId;
  final String creatorUsername;

  ListButton(
      {required this.listTitle,
      required this.creatorUsername,
      required this.listId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MediaListPage(
                      listId: listId,
                    )));
        print('Tapped on $listTitle');
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'By $creatorUsername',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final List<Tab> listTabs = <Tab>[
    Tab(text: 'My Lists'),
    Tab(text: 'Saved Lists'),
  ];

  List<Map<String, dynamic>> myLists = []; // Store user's lists here

  @override
  void initState() {
    super.initState();
    // Load the user's lists when the page initializes
    _loadMyLists();
  }

  Future<void> _loadMyLists() async {
    final userId = 1; // Replace with the user's ID
    final apiUrl = Uri.parse(
        'https://app.medleyapp.co.uk/load_user_lists.php?userId=${userData.userId}'); // Replace with your PHP script URL

    try {
      final response = await http.get(apiUrl);
      print('lists here ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> parsedLists = json.decode(response.body);
        print('lists here ${parsedLists}');
        setState(() {
          myLists = parsedLists.cast<Map<String, dynamic>>();
        });
      } else {
        // Handle server error
        print('Error loading lists: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network error
      print('Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: listTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lists'),
          bottom: TabBar(
            tabs: listTabs,
            indicatorColor: Colors.white,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: listTabs.map((Tab tab) {
            if (tab.text == 'My Lists') {
              // Display the user's lists
              return ListView.builder(
                itemCount: myLists.length,
                itemBuilder: (context, index) {
                  final list = myLists[index];
                  return ListButton(
                    listId: list['listId'],
                    listTitle: list['listname'],
                    creatorUsername: userData
                        .username, // You can display the creator's username here
                  );
                },
              );
            } else {
              // Add content for 'Saved Lists' tab here
              return Center(child: Text('Saved Lists Tab'));
            }
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateListPage()),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}

class ListWidget extends StatefulWidget {
  var userId;
  ListWidget({required this.userId});
  @override
  _ListWidgetState createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  List<Map<String, dynamic>> myLists = []; // Store user's lists here

  @override
  void initState() {
    super.initState();
    _loadMyLists();
  }

  Future<void> _loadMyLists() async {
    final userId = 1; // Replace with the user's ID
    final apiUrl = Uri.parse(
        'https://app.medleyapp.co.uk/load_user_lists.php?userId=${widget.userId}'); // Replace with your PHP script URL

    try {
      final response = await http.get(apiUrl);
      print('lists here ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> parsedLists = json.decode(response.body);
        print('lists here ${parsedLists}');
        setState(() {
          myLists = parsedLists.cast<Map<String, dynamic>>();
        });
      } else {
        // Handle server error
        print('Error loading lists: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network error
      print('Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (myLists.isNotEmpty) {
      return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        itemCount: myLists.length,
        itemBuilder: (context, index) {
          final list = myLists[index];
          return ListButton(
            listId: list['listId'],
            listTitle: list['listname'],
            creatorUsername: userData
                .username, // You can display the creator's username here
          );
        },
      );
    } else {
      // Add content for 'Saved Lists' tab here
      return Center(child: Text('Saved Lists Tab'));
    }
  }
}

class MediaListPage extends StatefulWidget {
  final String listId; // Added listId as a named parameter

  MediaListPage({required this.listId});

  @override
  _MediaListPageState createState() => _MediaListPageState();
}

class _MediaListPageState extends State<MediaListPage> {
  bool isGridView = true; // Toggle between Grid and List view

  Future<List<dynamic>> fetchAlbumDetails() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/load_list.php?listId=${widget.listId}'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('response $data');
      return data['albumDetails'];
    } else {
      throw Exception('Failed to load album details');
    }
  }

  void refreshLibrary() {
    setState(() {
      // Perform any necessary updates here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media List'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_on),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
        ],
      ),
      body: isGridView
          ? Padding(padding: EdgeInsets.only(top: 10), child: _buildGridView())
          : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return FutureBuilder<List<dynamic>>(
      future: fetchAlbumDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var album = snapshot.data![index];
              return MediaTile(
                id: album[
                    'id'], // Placeholder, replace with actual ID if available
                artistName: album['artistName'],
                imageUrl:
                    album['coverImage'], // Update with actual path if needed
                title: album['title'],
                releaseDate:
                    '2023', // Placeholder, replace with actual release year if available
                refreshCall: refreshLibrary,
              );
            },
          );
        } else {
          return Text('No data found');
        }
      },
    );
  }

  Widget _buildListView() {
    return FutureBuilder<List<dynamic>>(
      future: fetchAlbumDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var album = snapshot.data![index];
              return MediaListTile(
                imageUrl:
                    album['coverImage'], // Update with actual path if needed
                title: album['title'],
                releaseDate:
                    '2023', // Placeholder, replace with actual release date if available
                position: index + 1,
              );
            },
          );
        } else {
          return Text('No data found');
        }
      },
    );
  }
}

class MediaListTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String releaseDate;
  final int position;

  MediaListTile({
    required this.imageUrl,
    required this.title,
    required this.releaseDate,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error); // In case the image fails to load
          },
        ),
        title: Text(title),
        subtitle: Text('Release Date: $releaseDate'),
        trailing: Text('#$position'),
      ),
    );
  }
}

class CreateListPage extends StatefulWidget {
  @override
  _CreateListPageState createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<int> selectedMediaIds = []; // List to store selected media IDs

  @override
  void dispose() {
    _listNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveList() async {
    // Define the PHP API URL
    var apiUrl = Uri.parse(
        'https://app.medleyapp.co.uk/create_list.php'); // Replace with your API URL

    // Prepare the data to be sent in the POST request
    var data = {
      'access_token':
          userData.accesstoken, // Replace with the user's access token
      'creatorid': userData.userId, // Replace with the user's ID
      'listname': _listNameController.text,
      'list': json
          .encode(selectedMediaIds), // Assuming selectedMediaIds is a List<int>
      'mediatype': 'music', // Replace with the selected media type
    };

    try {
      // Send the POST request to the API
      var response = await http.post(apiUrl, body: data);

      // Check the response status code
      if (response.statusCode == 200) {
        // List created successfully
        print('List created successfully');
      } else {
        // Handle server error
        print('Error creating list: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network error
      print('Network error: $e');
    }
  }

  String _selectedCategory = 'Movies'; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New List'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _listNameController,
                decoration: InputDecoration(
                  labelText: 'List Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: <String>['Movies', 'Music', 'Games']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final selectedMedia = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectMediaPage(
                        selectedMediaIds: selectedMediaIds,
                      ),
                    ),
                  ) as List<int>?;

                  if (selectedMedia != null) {
                    // Handle the selected media list here
                    setState(() {
                      selectedMediaIds = selectedMedia;
                    });
                  }
                },
                child: Text('Add Media'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveList,
                child: Text('Save List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectMediaPage extends StatefulWidget {
  final List<int> selectedMediaIds; // Receive selected media IDs

  SelectMediaPage({Key? key, required this.selectedMediaIds}) : super(key: key);

  @override
  _SelectMediaPageState createState() => _SelectMediaPageState();
}

class _SelectMediaPageState extends State<SelectMediaPage>
    with AutomaticKeepAliveClientMixin<SelectMediaPage> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  Map<int, int> selectedOrderMap = {}; // Track the selected order using a Map
  var _selectedMediaType = 'music';

  @override
  bool get wantKeepAlive => true; // Keep the state alive

  @override
  void initState() {
    super.initState();
    // Initialize the selectedOrderMap with existing selections
    for (int id in widget.selectedMediaIds) {
      selectedOrderMap[id] = selectedOrderMap.length + 1;
    }
  }

  void _performSearch(String query) async {
    // Add your search logic here...
    // Example HTTP request:
    var url = Uri.parse(
        'https://app.medleyapp.co.uk/search.php?mediaType=$_selectedMediaType&query=$query&searchFor=album');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          searchResults = json.decode(response.body);
        });
      } else {
        // Handle server error
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network error
      print('Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          onSubmitted: _performSearch,
        ),
      ),
      body: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          var result = searchResults[index];
          int albumId = int.parse(result['id']);
          bool isSelected = selectedOrderMap.containsKey(albumId);

          return AlbumInfoTile(
            albumart: result['coverImage'],
            albumname: result['title'],
            artistname: result['artistName'],
            albumid: albumId.toString(),
            isSelected: isSelected,
            selectedOrder: isSelected
                ? selectedOrderMap[albumId]
                : null, // Pass the selected order
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedOrderMap.remove(albumId);
                } else {
                  selectedOrderMap[albumId] =
                      selectedOrderMap.length + 1; // Assign the next order
                }
              });
            },
          );
        },
      ),
      floatingActionButton: selectedOrderMap.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // Logic for FAB
                print('Selected Orders: $selectedOrderMap');
                // Pass the selected media IDs back to CreateListPage
                Navigator.pop(context, selectedOrderMap.keys.toList());
              },
              child: Icon(Icons.check),
            )
          : null,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class AlbumInfoTile extends StatelessWidget {
  final String albumart;
  final String albumname;
  final String artistname;
  final String albumid;
  final bool isSelected;
  final int? selectedOrder; // Add selectedOrder
  final VoidCallback onTap;

  const AlbumInfoTile({
    Key? key,
    required this.albumart,
    required this.albumname,
    required this.artistname,
    required this.albumid,
    this.isSelected = false,
    this.selectedOrder, // Include selectedOrder
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Image.network(albumart),
        title: Text(albumname),
        subtitle: Text(artistname),
        trailing: isSelected
            ? Text(
                selectedOrder != null
                    ? selectedOrder.toString()
                    : '', // Display the selected order
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
        tileColor: isSelected ? Colors.lightBlue : null,
      ),
    );
  }
}

class SearchMediaPage extends StatefulWidget {
  @override
  _SearchMediaPageState createState() => _SearchMediaPageState();
}

class _SearchMediaPageState extends State<SearchMediaPage> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Focus the search field when the page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Clean up the focus node when the widget is disposed
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Media'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                labelText: 'Search for media',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (String value) {
                // Implement search logic
                print('Searching for: $value');
              },
            ),
            // Placeholder for search results...
          ],
        ),
      ),
    );
  }
}
