import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ArtistPage.dart';
import 'ReviewPage.dart';
import 'AlbumPage.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

class AlbumReviewsList extends StatelessWidget {
  final String title;
  final String albumId;
  final String coverArtUrl;

  AlbumReviewsList({
    required this.title,
    required this.albumId,
    required this.coverArtUrl,
  });

  Future<List<Review>> fetchReviews() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_album_review.php?albumid=$albumId'));
    print('review response ${response.body}');
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => Review.fromJson(data)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: fetchReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        } else if (snapshot.hasData) {
          print('response data ${snapshot.data}');
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Review review = snapshot.data![index];
              return ReviewTile(
                reviewTitle: review.title,
                profilePictureUrl: review
                    .profilePicture, // Add logic to get profile picture URL
                username: review.username,
                rating: int.parse(review.rating),
                reviewText: review.text,
                albumTitle: title,
                mediaType: 'Music', // Change this as per your requirements
                coverArtUrl: coverArtUrl, artistName: review.artistName,
                albumId: review.albumId, displayName: review.displayName,
              );
            },
          );
        } else {
          return Text('No reviews found');
        }
      },
    );
  }
}

Future<Widget> _buildRatingRow({required int albumId}) async {
  var url = Uri.parse(
      'https://app.medleyapp.co.uk/get_album_rating.php?albumid=$albumId');
  var response = await http.get(url);

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    var rating = data['AverageRating'] ?? 0.0;
    return _buildStars(rating);
  } else {
    // Handle the case when the server does not respond as expected
    return Text('Error: Unable to fetch rating');
  }
}

Widget _buildStars(double rating) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: List.generate(5, (index) {
      var adjustedRating = (rating * 2) - 1; // Adjust rating scale
      IconData icon;
      if (adjustedRating >= (index * 2) + 1) {
        icon = Icons.star;
      } else if (adjustedRating >= index * 2) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      return Icon(
        icon,
        color: icon == Icons.star_border ? Colors.grey : Colors.amber,
        size: 24,
      );
    }),
  );
}

class UserReviewsList extends StatelessWidget {
  final String userId;
  final String userName;
  UserReviewsList({
    required this.userName,
    required this.userId,
  });

  Future<dynamic> fetchReviews() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_user_reviews.php?userid=$userId'));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Review.fromJson(data)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: fetchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('No Reviews Found'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Review review = snapshot.data![index];
                print(review);
                return ReviewTile(
                  reviewTitle: review.title,
                  displayName: review.displayName,
                  profilePictureUrl: review.profilePicture,
                  username: review.displayName,
                  rating: int.parse(review.rating),
                  reviewText: review.text,
                  albumTitle: review.albumTitle,
                  mediaType: '',
                  coverArtUrl: review.coverImage,
                  artistName: review.artistName,
                  albumId: review.albumId,
                );
              },
            );
          }
          return Text('error');
        });
  }
}

class Review {
  final String id;
  final String userId;
  final String albumId;
  final String rating;
  final String title;
  final String text;
  final String time;
  final String albumTitle;
  final String artistName;
  final String coverImage;
  final String displayName;
  final String username;
  final String profilePicture;

  Review(
      {required this.id,
      required this.userId,
      required this.albumId,
      required this.rating,
      required this.title,
      required this.text,
      required this.time,
      required this.albumTitle,
      required this.artistName,
      required this.coverImage,
      required this.displayName,
      required this.profilePicture,
      required this.username});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
        profilePicture: json['profile_picture'],
        id: json['id'],
        userId: json['userid'],
        albumId: json['albumid'],
        rating: json['rating'],
        title: json['title'],
        text: json['text'],
        time: json['time'],
        displayName: json['displayname'],
        coverImage: json['coverImage'],
        albumTitle: json['albumTitle'],
        artistName: json['artistName'],
        username: json['username']);
  }
}

class FavouritesBox extends StatelessWidget {
  final String username;
  final String userid;
  final Function refreshCall;

  FavouritesBox(
      {required this.username,
      required this.userid,
      required this.refreshCall});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$username's Favourites",
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All'),
            ),
          ],
        ),
        Container(
          height: 200, // Adjust the height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10, // Number of items in the horizontal list
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 10), // Add spacing between tiles
                child: MediaTile(
                  artistName: 'name',
                  id: '1',
                  imageUrl: 'https://via.placeholder.com/150',
                  title: '',
                  releaseDate: '',
                  refreshCall: refreshCall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ArtistReleases extends StatefulWidget {
  final String id;
  final String artistName;
  final Function refreshCall;

  ArtistReleases(
      {required this.id, required this.artistName, required this.refreshCall});

  @override
  _ArtistReleasesState createState() => _ArtistReleasesState();
}

class _ArtistReleasesState extends State<ArtistReleases> {
  late Future<List<Map<String, dynamic>>> artistAlbums;

  @override
  void initState() {
    super.initState();
    artistAlbums = fetchArtistAlbums();
  }

  var apiKey = 'yAMnaIIyZhkWIKMimlvu';
  var apiSecret = 'XMBrcPWBhYMduAPDfclfBnfgVImXIrtm';
  Future<List<Map<String, dynamic>>> fetchArtistAlbums() async {
    // Replace with your Discogs API key

    final response = await http.get(
      Uri.parse(
        'https://api.discogs.com/artists/${widget.id}/releases?type=master&format=album&sort_order=desc&key=$apiKey&secret=$apiSecret',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> releases = data['releases'];

      // Transform the data into the desired format
      return releases.map<Map<String, dynamic>>((release) {
        return {
          'id': release['id'].toString(), // Use the release ID
          'title': release['title'],
          'coverImage': release[
              'thumb'], // You can adjust this to get a larger image if needed
        };
      }).toList();
    } else {
      throw Exception('Failed to load artist releases');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${widget.artistName}'s Releases",
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {
                // Handle the "View All" button action
              },
              child: Text('View All'),
            ),
          ],
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: artistAlbums,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // Display a loading indicator
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No albums found for this artist');
            } else {
              // Use the fetched data to populate the ListView.builder
              return Container(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    final album = snapshot.data![index];
                    return Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                      child: MediaTile(
                        artistName: widget.artistName,
                        id: album['id'],
                        imageUrl: album['coverImage'] ??
                            'https://via.placeholder.com/150',
                        title: album['title'] ?? '',
                        releaseDate:
                            '', // You may need to fetch the release date from Discogs if available
                        refreshCall: widget.refreshCall,
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class ReadyForReviewBox extends StatelessWidget {
  final Function refreshCall;

  ReadyForReviewBox({
    required this.refreshCall,
  });

  Future<List<dynamic>> fetchNotReviewedAlbums() async {
    final response = await http.get(
      Uri.parse(
          'https://app.medleyapp.co.uk/get_user_music_notreviewed.php?userId=${userData.userId}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['notReviewed'];
    } else {
      throw Exception('Failed to load not reviewed albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ready for Review',
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {
                // Handle the "View All" button press
              },
              child: Text('View All'),
            ),
          ],
        ),
        FutureBuilder<List<dynamic>>(
          future: fetchNotReviewedAlbums(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Container(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    var album = snapshot.data![index];
                    return Padding(
                      padding: EdgeInsets.only(
                          left:
                              index == 0 ? 0 : 10), // Add spacing between tiles
                      child: MediaTile(
                        id: album['id'].toString(),
                        artistName: album['artistName'],
                        imageUrl: album['coverImage'],
                        title: album['title'],
                        releaseDate: album['releaseDate'],
                        refreshCall: refreshCall,
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class RecentReleaseBox extends StatelessWidget {
  final Function refreshCall;

  RecentReleaseBox({
    required this.refreshCall,
  });

  Future<List<dynamic>> fetchAlbums() async {
    final response = await http
        .get(Uri.parse('https://app.medleyapp.co.uk/get_recent_albums.php'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Released',
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All'),
            ),
          ],
        ),
        FutureBuilder<List<dynamic>>(
          future: fetchAlbums(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Container(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    var album = snapshot.data![index];
                    return Padding(
                      padding: EdgeInsets.only(
                          left:
                              index == 0 ? 0 : 10), // Add spacing between tiles
                      child: MediaTile(
                        id: album['id'].toString(),
                        artistName: album['ArtistName'],
                        imageUrl: album['coverImage'],
                        title: album['title'],
                        releaseDate: album['releaseDate'],
                        refreshCall: refreshCall,
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class RecentsBox extends StatelessWidget {
  final Function refreshCall;
  final userId;
  final username;

  RecentsBox(
      {required this.refreshCall,
      required this.userId,
      required this.username});

  Future<List<dynamic>> fetchAlbums() async {
    final response = await http.get(Uri.parse(
        'https://app.medleyapp.co.uk/get_library_recents.php?userId=$userId&isPreview=1'));
    if (response.statusCode == 200) {
      print('response ${response.body}');
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recently Added",
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All'),
            ),
          ],
        ),
        FutureBuilder<List<dynamic>>(
          future: fetchAlbums(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Container(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    var album = snapshot.data![index];
                    return Padding(
                      padding: EdgeInsets.only(
                          left:
                              index == 0 ? 0 : 10), // Add spacing between tiles
                      child: MediaTile(
                        id: album['id'].toString(),
                        artistName: album['artistName'],
                        imageUrl: album['coverImage'],
                        title: album['title'],
                        releaseDate: album['releaseDate'],
                        refreshCall: refreshCall,
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class PopularArtists extends StatelessWidget {
  final Function refreshCall;

  PopularArtists({
    required this.refreshCall,
  });

  Future<List<dynamic>> fetchArtists() async {
    final response = await http.get(Uri.parse(
        'http://ws.audioscrobbler.com/2.0/?method=chart.gettopartists&api_key=9a784967280311e92bfc9431a2780930&format=json'));
    if (response.statusCode == 200) {
      var respond = json.decode(response.body);
      print('response ${respond['artists']['artist']}');
      return respond['artists']['artist'];
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Popular Artists",
              style: TextStyle(fontSize: 20),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All'),
            ),
          ],
        ),
        FutureBuilder<List<dynamic>>(
          future: fetchArtists(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Container(
                height: 200, // Adjust the height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    var album = snapshot.data![index];
                    print('details of artist $album');
                    return Padding(
                      padding: EdgeInsets.only(
                          left:
                              index == 0 ? 0 : 10), // Add spacing between tiles
                      child: ArtistTile(
                        id: album['mbid'].toString(),
                        artistName: album['name'],
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class TrendingAlbums extends StatelessWidget {
  final Function refreshCall;

  TrendingAlbums({required this.refreshCall});

  var randomTag;

  Future<List<dynamic>> fetchTrendingAlbums() async {
    if (userTags.isEmpty) {
      randomTag = 'pop';
    } else {
      randomTag = userTags[Random().nextInt(userTags.length)];
    }

    final response = await http.get(Uri.parse(
        'http://ws.audioscrobbler.com/2.0/?method=tag.getTopAlbums&api_key=9a784967280311e92bfc9431a2780930&format=json&tag=$randomTag'));
    print('respond with trend ${response.body}');

    if (response.statusCode == 200) {
      var respond = json.decode(response.body);
      return respond['albums']['album'];
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchTrendingAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No trending albums found');
        } else {
          return CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 0.48,
              height: 232,
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
            ),
            items: snapshot.data!.map((album) {
              return Builder(
                builder: (BuildContext context) {
                  return MediaTile(
                    artistName: album['artist']['name'],
                    id: album['mbid'],
                    imageUrl: album['image'][2]['#text'], // Medium-sized image
                    title: album['name'],
                    releaseDate: '', // Release date not provided by Last.fm
                    refreshCall: refreshCall,
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }
}

class MediaTile extends StatelessWidget {
  final String imageUrl;
  final String artistName;
  final String title;
  final String releaseDate;
  final String id;
  final Size size; // New property to define the size of the tile
  final Function refreshCall;

  MediaTile({
    required this.imageUrl,
    required this.artistName,
    required this.title,
    required this.releaseDate,
    required this.id,
    required this.refreshCall,
    this.size = const Size(150, 225), // Default size, can be overridden
  });

  @override
  Widget build(BuildContext context) {
    bool isInLibrary = backlogIds.contains(id) || listenedIds.contains(id);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlbumPage(albumId: int.parse(id)),
            ),
          );
        },
        onLongPressStart: (details) {
          HapticFeedback.lightImpact();

          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              if (!isInLibrary)
                PopupMenuItem(
                  child: Text('Add to Library'),
                  value: 'Add to Library',
                  onTap: () async {
                    addToLibrary(userData.userId, userData.accesstoken, id);
                    await Future.delayed(Duration(milliseconds: 100));
                    await Future.delayed(Duration(milliseconds: 100));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added "$title" to your library.'),
                      backgroundColor: Colors.green,
                    ));
                    refreshCall();
                  },
                ),
              if (backlogIds.contains(id))
                PopupMenuItem(
                  child: Text('Move to Listened'),
                  value: 'Move to Listened',
                  onTap: () async {
                    moveToListened(userData.userId, userData.accesstoken, id);
                    await Future.delayed(Duration(milliseconds: 100));
                    await Future.delayed(Duration(milliseconds: 100));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Moved "$title" to Listened.'),
                      backgroundColor: Colors.green,
                    ));
                    refreshCall();
                  },
                ),
              if (listenedIds.contains(id))
                PopupMenuItem(
                  child: Text('Move to Backlog'),
                  value: 'Move to Backlog',
                  onTap: () async {
                    moveToBacklog(userData.userId, userData.accesstoken, id);
                    await Future.delayed(Duration(milliseconds: 100));
                    await Future.delayed(Duration(milliseconds: 100));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Moved "$title" to Backlog.'),
                      backgroundColor: Colors.green,
                    ));
                    refreshCall();
                  },
                ),
              PopupMenuItem(
                child: Text('Review'),
                value: 'Review',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReviewComposePage(
                                albumId: id,
                                albumTitle: title,
                                artistName: artistName,
                              )));
                },
              ),
              if (isInLibrary)
                PopupMenuItem(
                  child: Text('Delete'),
                  value: 'Remove from List',
                  onTap: () async {
                    removeFromLibrary(
                        userData.userId, userData.accesstoken, id);
                    await Future.delayed(Duration(milliseconds: 100));
                    await Future.delayed(Duration(milliseconds: 100));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Removed "$title" from your library.'),
                      backgroundColor: Colors.green,
                    ));
                    refreshCall();
                  },
                ),
            ],
          );
        },
        child: Container(
          height: 150,
          child: Image.network(
            imageUrl,
            fit: BoxFit
                .cover, // Ensures the image covers the container without distortion
          ),
        ),
      ),
      Container(
        alignment: Alignment.center,
        width: 150,
        child: Text(
          title,
          style: TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      Flexible(
        child: Text(
          artistName,
          style: TextStyle(fontSize: 10),
        ),
      ),
    ]);
  }
}

class ArtistTile extends StatelessWidget {
  final String artistName;
  final String id;

  ArtistTile({
    required this.artistName,
    required this.id,
  });

  late String imageUrl;

  Future<String?> fetchWikimediaImageUrl(String artistName) async {
    // Replace spaces with underscores (as in Wikipedia page titles)
    String formattedName = artistName.replaceAll(' ', '_');

    // Wikimedia API endpoint for getting page images
    var url = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&titles=$formattedName&prop=pageimages&format=json&pithumbsize=500');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var pages = data['query']['pages'];
        if (pages != null) {
          var page = pages[pages.keys.first];
          if (page != null && page['thumbnail'] != null) {
            imageUrl = page['thumbnail']['source'];
            return page['thumbnail']['source'];
          }
        }
      }
    } catch (e) {
      // Handle exceptions
    }
    imageUrl =
        'https://lastfm.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png';
    return 'https://lastfm.freetls.fastly.net/i/u/300x300/2a96cbd8b46e442fc41c2b86b821562f.png'; // Return empty string if no image found or in case of an error
  }

  @override
  Widget build(BuildContext context) {
    bool isInLibrary = false; // Replace with actual logic

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      GestureDetector(
        onTap: () {
          if (imageUrl != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ArtistPage(
                  artistId: int.parse(id),
                  artistName: artistName,
                ),
              ),
            );
          }
        },
        onLongPressStart: (details) {
          HapticFeedback.lightImpact();

          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              // Menu items
            ],
          );
        },
        child: FutureBuilder<String?>(
          future: fetchWikimediaImageUrl(artistName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return CircleAvatar(child: Icon(Icons.error));
            }
            return CircleAvatar(
              radius: 70, // Adjust the radius for the desired size
              backgroundImage: NetworkImage(snapshot.data!),
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image load error
              },
              backgroundColor:
                  Colors.transparent, // Optional: change background color
              // You can also add a child here for additional content or styling
            );
          },
        ),
      ),
      Flexible(
        child: RichText(
            text: TextSpan(
          text: artistName,
          style: TextStyle(fontSize: 14),
        )),
      ),
    ]);
  }
}

class UserComments extends StatelessWidget {
  final String userid; // Example data structure for comments

  UserComments({Key? key, required this.userid}) : super(key: key);

  List<Map<String, String>> comments = [{}];

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Text(
              "User Comments",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      ListView.builder(
        shrinkWrap: true, // To make ListView work within another scrolling view
        physics:
            NeverScrollableScrollPhysics(), // Disables scrolling within the ListView
        itemCount: comments.length,
        itemBuilder: (context, index) {
          var comment = comments[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(comment['profileImageUrl'] ?? ''),
              ),
              title: Text(comment['username'] ?? ''),
              subtitle: Text(comment['content'] ?? ''),
            ),
          );
        },
      ),
    ]));
  }
}
