import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/providers/audio_state.dart';
import 'package:tsacdop_desktop/providers/downloader.dart';
import 'package:tsacdop_desktop/widgets/custom_paint.dart';

import '../storage/sqflite_db.dart';
import '../utils/extension_helper.dart';
import '../models/episodebrief.dart';

class MenuButton extends StatelessWidget {
  final Function onTap;
  final Widget child;
  const MenuButton({this.child, this.onTap, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
            height: 40.0,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: child),
      ),
    );
    ;
  }
}

class FavIcon extends StatefulWidget {
  final EpisodeBrief episode;
  FavIcon(this.episode, {Key key}) : super(key: key);

  @override
  FavIconState createState() => FavIconState();
}

class FavIconState extends State<FavIcon> {
  var _dbHelper = DBHelper();
  Future<bool> _isLiked(EpisodeBrief episode) async {
    return await _dbHelper.isLiked(episode.enclosureUrl);
  }

  Future<void> _saveLiked(EpisodeBrief episode) async {
    await _dbHelper.setLiked(episode.enclosureUrl);
    if (mounted) setState(() {});
  }

  Future<void> _setUnliked(EpisodeBrief episode) async {
    await _dbHelper.setUniked(episode.enclosureUrl);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLiked(widget.episode),
      initialData: false,
      builder: (context, snapshot) {
        return snapshot.data
            ? MenuButton(
                onTap: () => _setUnliked(widget.episode),
                child: Icon(Icons.favorite),
              )
            : MenuButton(
                onTap: () => _saveLiked(widget.episode),
                child: Icon(
                  Icons.favorite_border,
                ));
      },
    );
  }
}

class DownloadIcon extends StatefulWidget {
  final EpisodeBrief episode;
  DownloadIcon(this.episode, {Key key}) : super(key: key);

  @override
  _DownloadIconState createState() => _DownloadIconState();
}

class _DownloadIconState extends State<DownloadIcon> {
  Future<bool> _isDownloaded() async {
    var dbHelper = DBHelper();
    return await dbHelper.isDownloaded(widget.episode.enclosureUrl);
  }

  Future<void> _deleleDonwload() async {
    await context.read(downloadProvider).deleteDownload(widget.episode);
    if (mounted) setState(() {});
  }

  void _download() {
    context.read(downloadProvider).download(widget.episode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isDownloaded(),
      initialData: false,
      builder: (context, snapshot) {
        if (snapshot.data)
          return InkWell(
            onTap: _deleleDonwload,
            child: Container(
              height: 50.0,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CustomPaint(
                  painter: DownloadPainter(
                    color: context.accentColor,
                    fraction: 1,
                    progressColor: context.accentColor,
                    progress: 1,
                  ),
                ),
              ),
            ),
          );
        return Consumer(
          builder: (context, watch, child) {
            final tasks = watch(downloadProvider.state);
            final index =
                context.read(downloadProvider).indexOf(widget.episode);
            if (index == -1)
              return InkWell(
                onTap: _download,
                child: Container(
                  height: 50.0,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CustomPaint(
                      painter: DownloadPainter(
                        color: Colors.grey[700],
                        fraction: 0,
                        progressColor: context.accentColor,
                      ),
                    ),
                  ),
                ),
              );
            return tasks[index].status != DownloadTaskStatus.complete
                ? MenuButton(
                    child: TweenAnimationBuilder(
                        duration: Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, fraction, child) => SizedBox(
                            height: 20,
                            width: 20,
                            child: CustomPaint(
                              painter: DownloadPainter(
                                  color: context.accentColor,
                                  fraction: fraction,
                                  progressColor: context.accentColor,
                                  progress: tasks[index].progress / 100),
                            ))))
                : MenuButton(
                    onTap: _deleleDonwload,
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CustomPaint(
                        painter: DownloadPainter(
                          color: context.accentColor,
                          fraction: 1,
                          progressColor: context.accentColor,
                          progress: 1,
                        ),
                      ),
                    ),
                  );
          },
        );
      },
    );
  }
}

class PlayButton extends StatefulWidget {
  final EpisodeBrief episode;
  PlayButton(this.episode, {Key key}) : super(key: key);

  @override
  _PlayButtonState createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  Future<bool> _isDownloaded() async {
    var dbHelper = DBHelper();
    return await dbHelper.isDownloaded(widget.episode.enclosureUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read(audioState).loadEpisode(widget.episode),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder(
              future: _isDownloaded(),
              initialData: false,
              builder: (context, snapshot) {
                return Container(
                    height: 40,
                    width: 120,
                    color:
                        snapshot.data ? context.accentColor : Colors.grey[700]);
              },
            ),
            Consumer(builder: (context, watch, child) {
              final tasks = watch(downloadProvider.state);
              final index =
                  context.read(downloadProvider).indexOf(widget.episode);
              if (index == -1) return Center();
              return tasks[index].status == DownloadTaskStatus.running
                  ? Positioned(
                      left: 0,
                      child: Container(
                          height: 40,
                          width: tasks[index].progress * 1.2,
                          color: context.accentColor),
                    )
                  : Center();
            }),
            Container(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(context.s.play,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.cloud_download, color: Colors.white)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
