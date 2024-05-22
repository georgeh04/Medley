import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'Widgets.dart';
import 'globals.dart';
import 'main.dart';

class ReviewComposePage extends StatefulWidget {
  final String albumId;
  final String albumTitle;
  final String artistName;

  ReviewComposePage({
    required this.albumId,
    required this.albumTitle,
    required this.artistName,
  });

  @override
  _ReviewComposePageState createState() => _ReviewComposePageState();
}

class _ReviewComposePageState extends State<ReviewComposePage> {
  double _rating = 3.0; // Initial rating (5 stars)
  final TextEditingController _reviewTitleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review for ${widget.albumTitle} by ${widget.artistName}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Your Rating (1-5):',
              style: TextStyle(fontSize: 18.0),
            ),
            SizedBox(height: 8.0),
            RatingBar.builder(
              initialRating: 3,
              minRating: 0.5,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _rating = rating;
                print(rating);
              },
            ),
            SizedBox(height: 24.0),
            Text(
              'Review Title:',
              style: TextStyle(fontSize: 18.0),
            ),
            TextField(
              controller: _reviewTitleController,
              decoration: InputDecoration(
                hintText: 'Enter a title for your review',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Your Review:',
              style: TextStyle(fontSize: 18.0),
            ),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your review here',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () async {
                // Handle review submission
                int ratingAsNumber =
                    (_rating * 2).round(); // Convert to 1-10 rating
                String reviewTitle = _reviewTitleController.text;
                String reviewText = _reviewController.text;

                print('Album ID: ${widget.albumId}');
                print('Rating: $ratingAsNumber');
                print('Review Title: $reviewTitle');
                print('Review Text: $reviewText');
                var review = await createMusicReview(
                    userData.userId,
                    userData.accesstoken,
                    widget.albumId,
                    ratingAsNumber.toString(),
                    reviewTitle,
                    reviewText);
                if (review.contains('Error')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(('An error occurred when creating your review.')),
                    backgroundColor: Colors.redAccent,
                  ));
                } else {
                  Future.delayed(Duration(milliseconds: 100));
                  Future.delayed(Duration(milliseconds: 100));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Created review successfully.'),
                    backgroundColor: Colors.green,
                  ));
                  print('response review is ${review}');
                  Navigator.pop(context);
                }
              },
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class YourReviewsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Your Reviews'),
        ),
        body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: UserReviewsList(
                userId: userData.userId, userName: userData.username)));
  }
}

class ReviewPage extends StatelessWidget {
  final String albumTitle;
  final String artistName;
  final String coverArtUrl;
  final String albumId;
  final String profilePictureUrl;
  final String username;
  final String displayName;
  final int rating;
  final String reviewText;
  final String reviewTitle;
  final String mediaType;

  ReviewPage(
      {required this.albumTitle,
      required this.artistName,
      required this.coverArtUrl,
      required this.albumId,
      required this.profilePictureUrl,
      required this.username,
      required this.rating,
      required this.reviewText,
      required this.reviewTitle,
      required this.mediaType,
      required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  coverArtUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(albumTitle,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                      Text(artistName,
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      _buildRatingRow(),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://app.medleyapp.co.uk/profilepics/$profilePictureUrl'),
                  radius: 25,
                ),
                SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(username,
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          color: Colors.grey))
                ])
              ],
            ),
            SizedBox(height: 20),
            Text(
              reviewTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              reviewText,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        var adjustedRating = rating - 1;
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
}

class ReviewListPage extends StatelessWidget {
  final String displayName;
  final String userid;

  ReviewListPage({
    required this.displayName,
    required this.userid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" $displayName's Reviews"),
      ),
      body: ListView(
        children: [
          ReviewTile(
            reviewTitle: '',
            displayName: '',
            profilePictureUrl: 'https://example.com/profile.jpg',
            username: 'User123',
            rating: 9,
            reviewText: 'I really enjoyed this movie!',
            albumTitle: 'Inception',
            mediaType: 'Film',
            coverArtUrl: 'https://via.placeholder.com/150',
            artistName: '',
            albumId: '',
          )

          // Add more ReviewTiles as needed
        ],
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  final String albumTitle;
  final String artistName;
  final String coverArtUrl;
  final String albumId;
  final String profilePictureUrl;
  final String username;
  final int rating;
  final String reviewText;
  final String mediaType;
  final String reviewTitle;
  final String displayName;

  ReviewTile(
      {required this.albumTitle,
      required this.artistName,
      required this.coverArtUrl,
      required this.albumId,
      required this.profilePictureUrl,
      required this.username,
      required this.displayName,
      required this.rating,
      required this.reviewText,
      required this.mediaType,
      required this.reviewTitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReviewPage(
                        displayName: displayName,
                        albumTitle: albumTitle,
                        artistName: artistName,
                        coverArtUrl: coverArtUrl,
                        albumId: albumId,
                        profilePictureUrl: profilePictureUrl,
                        username: username,
                        rating: rating,
                        reviewText: reviewText,
                        mediaType: mediaType,
                        reviewTitle: reviewTitle,
                      )));
        },
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.network(
                      coverArtUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 8),
                    _buildRatingRow(), // Star rating beneath the cover art
                  ],
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(albumTitle,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(mediaType,
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text(
                        reviewTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildRatingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        // Adjust the rating to a 0-9 scale
        var adjustedRating = rating - 1;

        // Determine the icon type based on the adjusted rating
        IconData icon;
        if (adjustedRating >= (index * 2) + 1) {
          icon = Icons.star; // Full star
        } else if (adjustedRating >= index * 2) {
          icon = Icons.star_half; // Half star
        } else {
          icon = Icons.star_border; // Empty star
        }

        return Icon(
          icon,
          color: icon == Icons.star_border ? Colors.grey : Colors.amber,
          size: 16, // Smaller star icons
        );
      }),
    );
  }
}

Future<String> createMusicReview(
  userId,
  accessToken,
  albumId,
  rating,
  title,
  text,
) async {
  final url = Uri.parse('https://app.medleyapp.co.uk/create_musicreview.php');

  final requestBody = {
    'userid': userId.toString(),
    'access_token': accessToken,
    'albumid': albumId.toString(),
    'rating': rating.toString(),
    'title': title,
    'text': text,
  };

  try {
    final response = await http.post(
      url,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.containsKey('message')) {
        // Review created successfully
        return 'Review here ${responseData}';
      } else if (responseData.containsKey('error')) {
        // Error occurred during review creation
        return 'Error: ${responseData['error']}';
      }
    } else {
      // HTTP request failed
      return 'Failed to create review. HTTP status code: ${response.statusCode}';
    }
  } catch (error) {
    // Exception occurred
    return 'Error: $error';
  }
  return 'Error';
}
