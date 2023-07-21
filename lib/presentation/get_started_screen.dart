import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_mates_app/core/constants.dart';
import 'package:music_mates_app/main.dart';
import 'package:music_mates_app/presentation/select_favourite_artist.dart';
import 'package:music_mates_app/presentation/widgets/google_button.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_mates_app/data/model/error.dart';
import 'package:music_mates_app/presentation/presentation_export.dart';
import 'package:music_mates_app/presentation/query_document_provider.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  _GetStartedScreenState createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final googleSignin = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "https://www.kindpng.com/picc/m/355-3557482_flutter-logo-png-transparent-png.png",
              width: 120,
              height: 120,
            ),
            AppSpacing.v24,
            Mutation(
              options: MutationOptions(
                document: gql(context.queries.createAccount()),
                onCompleted: (data) => _onCompleted(data, context),
              ),
              builder: (RunMutation runMutation, QueryResult? result) {
                if (result != null) {
                  if (result.isLoading) {
                    return const LoadingSpinner();
                  }

                  if (result.hasException) {
                    context.showError(
                      ErrorModel.fromGraphError(
                        result.exception?.graphqlErrors ?? [],
                      ),
                    );
                  }
                }

                return GoogleButton(
                  onPressed: () => _googleButtonPressed(context, runMutation),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _onCompleted(data, BuildContext context) {
    /// We get the user's favorite artist field from the data
    final favouriteArtists = data['createUser']['user']['favouriteArtists'];

    /// Check if the user has selected artists
    final bool hasSelectedArtist =
        favouriteArtists != null && favouriteArtists.isNotEmpty;

    /// If they do, move to home page. If not, take them to select artist page for them to select artists.
    Navigator.popAndPushNamed(
      context,
      hasSelectedArtist ? Routes.home : Routes.selectArtist,
    );
  }

  /*Future<void> _googleButtonPressed(BuildContext context) async {
    final selectedArtist = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectFavouriteArtist(),
        fullscreenDialog: true,
      ),
    );

    if (selectedArtist == null) return;

    Navigator.popAndPushNamed(context, Routes.home);
  }*/

  Future<void> _googleButtonPressed(
      BuildContext context, RunMutation runMutation) async {
    /// Use the Google Sign-In package to initiate the Google Sign-In
    final googleUser = await googleSignin.signIn();

    if (googleUser == null) return;

    /// Cache the Google ID to be used across the app
    context.cacheGoogleId(googleUser.id);

    /// Trigger the mutation query by calling [runMutation] and passing in the mutation variable
    runMutation(
      {
        'name': googleUser.displayName,
        'googleId': googleUser.id,
        'imageUrl': googleUser.photoUrl!,
        'favouriteArtists': [],
      },
    );
  }
}
