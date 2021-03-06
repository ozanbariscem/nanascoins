import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/Asset.dart';
import '../models/Language.dart';
import '../models/BuildUtils.dart';

import '../widget/search_result_card.dart';
import '../widget/search_card.dart';

import 'package:nanas_coins/models/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class SearchView extends StatefulWidget {
  SearchView({Key key}) : super(key: key);

  @override
  _SearchView createState() => _SearchView();
}

class _SearchView extends State<SearchView> {
  List<NativeAd> _ads = [];

  ScrollController scrollController;

  bool gotData = false;
  List assetList = [];
  List searchResults = [];
  bool isSearching = false;

  int pageNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadAds();
    scrollController = new ScrollController()..addListener(scrollListener);

    if (Asset.assetList == null || Asset.assetList.length <= 0) {
      Asset.getEveryCoin().then((value) {
        getAssetList();
      });
    } else {
      getAssetList();
    }
  }

  @override
  void dispose() {
    for (int i = 0; i >= 0; i--) {
      try {
        _ads[i]?.dispose();
        _ads[i] = null;
      } catch (ex) {
        print("banner dispose error");
      }
    }
    _ads.clear();

    super.dispose();
  }

  Future<void> _refresh() async {
    pageNumber = 1;
    assetList = [];
    getAssetList();
  }

  void _loadAds({int amount=2}){
    for (int i = 0; i < amount; i++) {
      var _ad = NativeAd(
        adUnitId: AdHelper.nativeAdUnitId,
        factoryId: 'listTile',
        request: AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (_) {
            _ads.add(_);
            setState(() {
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Releases an ad resource when it fails to load
            ad.dispose();
            print('Ad load failed (code=${error.code} message=${error.message})');       },
        ),
      );
      _ad.load();
    }
  }

  void getAssetList() {
    Asset.getCoinsPage(20, pageNumber).then((value) {
      setState(() {
          gotData = true;
          assetList.addAll(value);
        }
      );
    });
  }

  void scrollListener() {
    if (scrollController.position.maxScrollExtent == scrollController.offset) {
      // Gets till first 100
      if (assetList.length != Asset.assetList.length) {
        pageNumber++;
        _loadAds();
        getAssetList();
      }
    }
  }

  Widget buildSearchResult() {
    var coinList = assetList;
    if (isSearching) {
      if (searchResults.length == 0)
        return Text(
          Language.language.map["SEARCH_NOT_FOUND"],
          style: BuildUtils.headerTextStyle(context),);
      else
        coinList = searchResults;
    }
    return ListView.separated(
      itemCount: coinList.length,
      controller: scrollController,
      itemBuilder: (context, i) {
          return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BuildUtils.buildEmptySpaceHeight(
                context, 0.002),
            SearchResultCard(asset: coinList[i]),
            BuildUtils.buildEmptySpaceHeight(
                context, 0.002)
          ],
        );
      },
      separatorBuilder: (context, i) {
        // if first statement is false
        // we don't have anymore loaded ads so we skip
        // but on load calls setState anyways
        // so in future the state gets reloaded anyways
        if (i~/10 < _ads.length && i % 10 == 9 && i != 0) {
          return Column(
            children: [
              BuildUtils.buildEmptySpaceHeight(
                  context, 0.002),
              Container(
                  height: MediaQuery.of(context).size.height * .08,
                  width: MediaQuery.of(context).size.width * .98,
                  decoration: BuildUtils.buildBoxDecoration(context),
                  child: Padding(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.height * .01),
                      child: Container(
                          width: double.infinity,
                          child: AdWidget(ad: _ads[i~/10])
                      )
                  )
              ),
              BuildUtils.buildEmptySpaceHeight(
                  context, 0.002)
            ],
          );
        }
        return BuildUtils.buildEmptySpaceHeight(context, 0.00001);
      },
    );
  }

  Widget buildList() {
    return RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            BuildUtils.buildEmptySpaceHeight(context, 0.005),
            SearchCard(
              onTextChanged: (isSearching, results) {
                setState(() {
                  this.isSearching = isSearching;
                  this.searchResults = results;
                });
              },
            ),
            BuildUtils.buildEmptySpaceHeight(context, 0.005),
            Container(
                height: MediaQuery.of(context).size.height * .8,
                // Listview.builder creates items in the list as we scroll down
                child : buildSearchResult()
            )
          ],
        ));
  }

  Widget buildWait() {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            BuildUtils.buildEmptySpaceHeight(context, 0.02),
            Text(
                Language.language.map["SEARCH_WAIT"],
                style: BuildUtils.linkTextStyle(
                    context: context,
                    fontSize: 0.02,
                    fontWeight: FontWeight.bold
                )
            )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Language.language.map["SEARCH"])),
      resizeToAvoidBottomInset: false,
      backgroundColor: BuildUtils.backgroundColor,
      body: Center(
          child:
          gotData ? buildList() : buildWait()
      ),
    );
  }
}
