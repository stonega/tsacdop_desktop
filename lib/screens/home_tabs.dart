import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/providers/downloader.dart';
import 'package:tsacdop_desktop/storage/key_value_storage.dart';
import 'package:tsacdop_desktop/storage/sqflite_db.dart';
import 'package:tsacdop_desktop/widgets/custom_paint.dart';
import 'package:tsacdop_desktop/widgets/episodes_grid.dart';
import 'package:tsacdop_desktop/widgets/podcast_menu.dart';

import '../utils/extension_helper.dart';

class HomeTabs extends StatelessWidget {
  const HomeTabs({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              tabs: [
                Tab(text: s.homeTabMenuRecent),
                Tab(text: s.homeTabMenuFavotite),
                Tab(text: s.download)
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RecentTab(),
                FavTab(),
                DownloadTab(),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class RecentTab extends StatefulWidget {
  RecentTab({Key key}) : super(key: key);

  @override
  _RecentTabState createState() => _RecentTabState();
}

class _RecentTabState extends State<RecentTab> {
  final _dbHelper = DBHelper();

  /// Episodes loaded first time.
  int _top = 90;

  /// Load more episodes when scroll to bottom.
  bool _loadMore;

  /// For group fliter.
  String _groupName;
  List<String> _group;
  Layout _layout;
  bool _hideListened;
  bool _scroll;

  ///Selected episode list.
  List<EpisodeBrief> _selectedEpisodes;

  ///Toggle for multi-select.
  bool _multiSelect;

  @override
  void initState() {
    super.initState();
    _loadMore = false;
    _groupName = 'All';
    _group = [];
    _scroll = false;
    _multiSelect = false;
  }

  Future<List<EpisodeBrief>> _getRssItem(int top, List<String> group,
      {bool hideListened}) async {
    var storage = KeyValueStorage(recentLayoutKey);
    var hideListenedStorage = KeyValueStorage(hideListenedKey);
    var index = await storage.getInt(defaultValue: 1);
    if (_layout == null) _layout = Layout.values[index];
    if (_hideListened == null) {
      _hideListened = await hideListenedStorage.getBool(defaultValue: false);
    }

    List<EpisodeBrief> episodes;
    if (group.isEmpty) {
      episodes =
          await _dbHelper.getRecentRssItem(top, hideListened: _hideListened);
    } else {
      episodes = await _dbHelper.getGroupRssItem(top, group,
          hideListened: _hideListened);
    }
    return episodes;
  }

  Future<void> _loadMoreEpisode() async {
    if (mounted) setState(() => _loadMore = true);
    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _top = _top + 30;
        _loadMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<List<EpisodeBrief>>(
        future: _getRssItem(_top, _group, hideListened: _hideListened),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return snapshot.data.length == 0
                ? Padding(
                    padding: EdgeInsets.only(top: 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(LineIcons.cloud_download_alt_solid,
                            size: 80, color: Colors.grey[500]),
                        Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                        Text(
                          s.noEpisodeRecent,
                          style: TextStyle(color: Colors.grey[500]),
                        )
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo is ScrollStartNotification &&
                          mounted &&
                          !_scroll) {
                        setState(() => _scroll = true);
                      }
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          snapshot.data.length == _top) {
                        if (!_loadMore) {
                          _loadMoreEpisode();
                        }
                      }
                      return true;
                    },
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraint) => Scrollbar(
                            child: CustomScrollView(slivers: <Widget>[
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 40,
                                ),
                              ),
                              EpisodesGrid(
                                width: constraint.maxWidth,
                                episodes: snapshot.data,
                                layout: _layout,
                                initNum: 0,
                                multiSelect: _multiSelect,
                                selectedList: _selectedEpisodes ?? [],
                                onSelect: (value) => setState(() {
                                  _selectedEpisodes = value;
                                }),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _loadMore
                                        ? Container(
                                            height: 2,
                                            child: LinearProgressIndicator())
                                        : Center();
                                  },
                                  childCount: 1,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        Column(
                          children: [
                            if (!_multiSelect)
                              Container(
                                  height: 40,
                                  color: context.scaffoldBackgroundColor
                                      .withOpacity(0.6),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: <Widget>[
                                        Spacer(),
                                        Material(
                                          color: Colors.transparent,
                                          child: IconButton(
                                            tooltip: s.hideListenedSetting,
                                            icon: SizedBox(
                                              width: 30,
                                              height: 15,
                                              child: HideListened(
                                                hideListened:
                                                    _hideListened ?? false,
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() => _hideListened =
                                                  !_hideListened);
                                            },
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: LayoutButton(
                                            layout: _layout,
                                            onPressed: (layout) => setState(() {
                                              _layout = layout;
                                            }),
                                          ),
                                        ),
                                        Material(
                                            color: Colors.transparent,
                                            child: IconButton(
                                              icon: SizedBox(
                                                width: 20,
                                                height: 10,
                                                child: CustomPaint(
                                                    painter: MultiSelectPainter(
                                                        color: context
                                                            .accentColor)),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedEpisodes = [];
                                                  _multiSelect = true;
                                                });
                                              },
                                            )),
                                      ],
                                    ),
                                  )),
                            if (_multiSelect)
                              MultiSelectMenuBar(
                                selectedList: _selectedEpisodes,
                                onClose: (value) {
                                  setState(() {
                                    if (value) {
                                      _multiSelect = false;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
          else
            return Center();
        });
  }
}

class FavTab extends StatefulWidget {
  FavTab({Key key}) : super(key: key);

  @override
  _FavTabState createState() => _FavTabState();
}

class _FavTabState extends State<FavTab> {
  final _dbHelper = DBHelper();

  /// Episodes loaded first time.
  int _top = 90;

  /// Load more episodes when scroll to bottom.
  bool _loadMore;

  Layout _layout;
  bool _hideListened;
  bool _scroll;
  int _sortBy;

  ///Selected episode list.
  List<EpisodeBrief> _selectedEpisodes;

  ///Toggle for multi-select.
  bool _multiSelect;

  @override
  void initState() {
    super.initState();
    _loadMore = false;
    _scroll = false;
    _sortBy = 0;
    _multiSelect = false;
  }

  Future<List<EpisodeBrief>> _getLikedRssItem(int top, int sortBy,
      {bool hideListened}) async {
    var storage = KeyValueStorage(favLayoutKey);
    var index = await storage.getInt(defaultValue: 1);
    var hideListenedStorage = KeyValueStorage(hideListenedKey);
    if (_layout == null) _layout = Layout.values[index];
    if (_hideListened == null) {
      _hideListened = await hideListenedStorage.getBool(defaultValue: false);
    }
    var dbHelper = DBHelper();
    var episodes = await dbHelper.getLikedRssItem(top, sortBy,
        hideListened: _hideListened);
    return episodes;
  }

  Future<void> _loadMoreEpisode() async {
    if (mounted) setState(() => _loadMore = true);
    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _top = _top + 30;
        _loadMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<List<EpisodeBrief>>(
        future: _getLikedRssItem(_top, _sortBy, hideListened: _hideListened),
        builder: (context, snapshot) {
          if (snapshot.hasData)
            return snapshot.data.length == 0
                ? Padding(
                    padding: EdgeInsets.only(top: 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(LineIcons.cloud_download_alt_solid,
                            size: 80, color: Colors.grey[500]),
                        Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                        Text(
                          s.noEpisodeRecent,
                          style: TextStyle(color: Colors.grey[500]),
                        )
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo is ScrollStartNotification &&
                          mounted &&
                          !_scroll) {
                        setState(() => _scroll = true);
                      }
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          snapshot.data.length == _top) {
                        if (!_loadMore) {
                          _loadMoreEpisode();
                        }
                      }
                      return true;
                    },
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraint) =>
                              CustomScrollView(slivers: <Widget>[
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 40,
                              ),
                            ),
                            EpisodesGrid(
                              width: constraint.maxWidth,
                              episodes: snapshot.data,
                              layout: _layout,
                              initNum: 0,
                              multiSelect: _multiSelect,
                              selectedList: _selectedEpisodes ?? [],
                              onSelect: (value) => setState(() {
                                _selectedEpisodes = value;
                              }),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _loadMore
                                      ? Container(
                                          height: 2,
                                          child: LinearProgressIndicator())
                                      : Center();
                                },
                                childCount: 1,
                              ),
                            ),
                          ]),
                        ),
                        Column(
                          children: [
                            if (!_multiSelect)
                              Container(
                                  height: 40,
                                  color: context.scaffoldBackgroundColor
                                      .withOpacity(0.6),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: <Widget>[
                                        Spacer(),
                                        Material(
                                          color: Colors.transparent,
                                          child: IconButton(
                                            tooltip: s.hideListenedSetting,
                                            icon: SizedBox(
                                              width: 30,
                                              height: 15,
                                              child: HideListened(
                                                hideListened:
                                                    _hideListened ?? false,
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() => _hideListened =
                                                  !_hideListened);
                                            },
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: LayoutButton(
                                            layout: _layout,
                                            onPressed: (layout) => setState(() {
                                              _layout = layout;
                                            }),
                                          ),
                                        ),
                                        Material(
                                            color: Colors.transparent,
                                            child: IconButton(
                                              icon: SizedBox(
                                                width: 20,
                                                height: 10,
                                                child: CustomPaint(
                                                    painter: MultiSelectPainter(
                                                        color: context
                                                            .accentColor)),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedEpisodes = [];
                                                  _multiSelect = true;
                                                });
                                              },
                                            )),
                                      ],
                                    ),
                                  )),
                            if (_multiSelect)
                              MultiSelectMenuBar(
                                selectedList: _selectedEpisodes,
                                onClose: (value) {
                                  setState(() {
                                    if (value) {
                                      _multiSelect = false;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
          else
            return Center();
        });
  }
}

class DownloadTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    var tasks = watch(downloadProvider.state);
    if (tasks.isEmpty) return Center();
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(
            task.episode.title,
            maxLines: 1,
          ),
          subtitle: task.status == DownloadTaskStatus.complete
              ? Center()
              : SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: tasks[index].progress / 100,
                  ),
                ),
        );
      },
    );
  }
}