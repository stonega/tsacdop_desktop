import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';

import '../generated/l10n.dart';
import '../providers/settings_state.dart';
import '../storage/key_value_storage.dart';
import '../utils/extension_helper.dart';
import '../widgets/color_picker.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Widget _settings;
  @override
  void initState() {
    _settings = ThemeSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              ListTile(
                onTap: () {
                  setState(() {
                    _settings = ThemeSettings();
                  });
                },
                leading:
                    Icon(LineIcons.adjust_solid, color: context.accentColor),
                title: Text(s.settingsAppearance),
                subtitle: Text(s.settingsAppearanceDes),
              ),
              ListTile(
                onTap: () => setState(() => _settings = StorageSetting()),
                leading: Icon(LineIcons.save, color: Colors.green[700]),
                title:
                    Text(s.settingStorage, style: context.textTheme.bodyText1),
                subtitle: Text(
                  s.settingsStorageDes,
                ),
              ),
              ListTile(
                onTap: () => setState(() => _settings = LanguageSetting(
                      onChange: () => setState(() {}),
                    )),
                leading:
                    Icon(LineIcons.language_solid, color: Colors.purpleAccent),
                title: Text(s.settingsLanguages),
                subtitle: Text(s.settingsLanguagesDes),
              ),
              ListTile(
                leading: Icon(LineIcons.file_code_solid,
                    color: Colors.lightGreen[700]),
                title: Text(s.settingsBackup),
                subtitle: Text(s.settingsBackupDes),
              ),
              ListTile(
                  leading: Icon(LineIcons.book_open_solid,
                      color: Colors.purple[700]),
                  title: Text(s.settingsLibraries),
                  subtitle: Text(s.settingsLibrariesDes)),
            ],
          ),
        ),
        Container(
          width: 1,
          height: double.infinity,
          color: context.primaryColorDark,
        ),
        Expanded(
          flex: 2,
          child: AnimatedSwitcher(
            child: _settings,
            duration: Duration(milliseconds: 300),
          ),
        )
      ],
    );
  }
}

class ThemeSettings extends ConsumerWidget {
  const ThemeSettings({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final s = context.s;
    final currentSetting = watch(settings);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
          ),
          Container(
            height: 30.0,
            padding: EdgeInsets.symmetric(horizontal: 30),
            alignment: Alignment.centerLeft,
            child: Text(s.settingsTheme,
                style: TextStyle(color: context.accentColor)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: Material(
              color: Colors.transparent,
              child: RadioListTile(
                  title: Text(s.systemDefault),
                  value: ThemeMode.system,
                  groupValue: currentSetting.themeMode,
                  onChanged: (value) {
                    context.read(settings).setTheme = value;
                  }),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: Material(
              color: Colors.transparent,
              child: RadioListTile(
                  title: Text(s.darkMode),
                  value: ThemeMode.dark,
                  groupValue: currentSetting.themeMode,
                  onChanged: (value) {
                    context.read(settings).setTheme = value;
                  }),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: Material(
              color: Colors.transparent,
              child: RadioListTile(
                  title: Text(s.lightMode),
                  value: ThemeMode.light,
                  groupValue: currentSetting.themeMode,
                  onChanged: (value) {
                    context.read(settings).setTheme = value;
                  }),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            alignment: Alignment.centerLeft,
            child: Text(s.settingsAccentColor,
                style: TextStyle(color: context.accentColor)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ColorPicker(
                onColorChanged: (value) =>
                    currentSetting.setAccentColor = value,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class LanguageSetting extends StatefulWidget {
  final Function() onChange;
  const LanguageSetting({this.onChange, Key key}) : super(key: key);

  @override
  _LanguageSettingState createState() => _LanguageSettingState();
}

class _LanguageSettingState extends State<LanguageSetting> {
  Future<void> _setLocale(Locale locale, {bool systemDefault = false}) async {
    var localeStorage = KeyValueStorage(localeKey);
    if (systemDefault) {
      await localeStorage.saveStringList([]);
      await findSystemLocale();
      var systemLanCode;
      final list = Intl.systemLocale.split('_');
      if (list.length == 2) {
        systemLanCode = list.first;
      } else if (list.length == 3) {
        systemLanCode = '${list[0]}_${list[1]}';
      } else {
        systemLanCode = 'en';
      }
      await S.load(Locale(systemLanCode));
      if (mounted) {
        setState(() {});
        widget.onChange();
      }
    } else {
      await localeStorage
          .saveStringList([locale.languageCode, locale.countryCode]);
      await S.load(locale);
      if (mounted) {
        setState(() {});
        widget.onChange();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    findSystemLocale();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          ListTile(
            title: Text(
              s.systemDefault,
              style: TextStyle(
                  color: Intl.systemLocale.contains(Intl.getCurrentLocale())
                      ? context.accentColor
                      : null),
            ),
            onTap: () =>
                _setLocale(Locale(Intl.systemLocale), systemDefault: true),
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
          ),
          Divider(height: 1),
          ListTile(
              title: Text('English'),
              onTap: () => _setLocale(Locale('en')),
              contentPadding: const EdgeInsets.only(left: 20, right: 20),
              trailing: Radio<Locale>(
                  value: Locale('en'),
                  groupValue: Locale(Intl.getCurrentLocale()),
                  onChanged: _setLocale)),
          Divider(height: 1),
          ListTile(
              title: Text('简体中文'),
              onTap: () => _setLocale(Locale('zh_Hans')),
              contentPadding: const EdgeInsets.only(left: 20, right: 20),
              trailing: Radio<Locale>(
                value: Locale('zh_Hans'),
                groupValue: Locale(Intl.getCurrentLocale()),
                onChanged: _setLocale,
              )),
          Divider(height: 1),
          ListTile(
            title: Text('Français'),
            onTap: () => _setLocale(Locale('fr')),
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
            trailing: Radio<Locale>(
                value: Locale('fr'),
                groupValue: Locale(Intl.getCurrentLocale()),
                onChanged: _setLocale),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Español'),
            onTap: () => _setLocale(Locale('es')),
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
            trailing: Radio<Locale>(
                value: Locale('es'),
                groupValue: Locale(Intl.getCurrentLocale()),
                onChanged: _setLocale),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Português'),
            onTap: () => _setLocale(Locale('pt')),
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
            trailing: Radio<Locale>(
                value: Locale('pt'),
                groupValue: Locale(Intl.getCurrentLocale()),
                onChanged: _setLocale),
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Italiano'),
            onTap: () => _setLocale(Locale('it')),
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
            trailing: Radio<Locale>(
                value: Locale('it'),
                groupValue: Locale(Intl.getCurrentLocale()),
                onChanged: _setLocale),
          ),
          Divider(height: 1),
          ListTile(
            onTap: () =>
                'mailto:<tsacdop.app@gmail.com>?subject=Tsacdop localization project'
                    .launchUrl,
            contentPadding: const EdgeInsets.only(left: 20, right: 20),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Image(
                  image: Theme.of(context).brightness == Brightness.light
                      ? AssetImage('assets/localizely_logo.png')
                      : AssetImage('assets/localizely_logo_light.png'),
                  height: 20),
            ),
            subtitle: Text(
                "If you'd like to contribute to localization project, please contact me."),
          ),
        ],
      ),
    );
  }
}

class StorageSetting extends StatefulWidget {
  StorageSetting({Key key}) : super(key: key);

  @override
  _StorageSettingState createState() => _StorageSettingState();
}

class _StorageSettingState extends State<StorageSetting> {
  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.zero, borderSide: BorderSide(color: color));
  FocusNode _focusNode;
  String _query;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Container(
          height: 30.0,
          padding: EdgeInsets.symmetric(horizontal: 30),
          alignment: Alignment.centerLeft,
          child: Text(s.network, style: TextStyle(color: context.accentColor)),
        ),
        Consumer(builder: (context, watch, child) {
          final currentSetting = watch(settings);
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Proxy settings: ${currentSetting.proxy}',
            ),
          );
        }),
        Container(
          height: 30,
          width: 400,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                    focusNode: _focusNode,
                    onSubmitted: (value) =>
                        context.read(settings).setProxy = value,
                    onChanged: (value) => _query = value,
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        focusColor: context.primaryColor,
                        hoverColor: context.primaryColor,
                        hintText: '127.0.0.1:8080',
                        fillColor: context.primaryColor,
                        filled: true,
                        border: _inputBorder(context.primaryColorDark),
                        focusedBorder: _inputBorder(context.accentColor))),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                child: Text(s.save),
                style: OutlinedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: context.accentColor,
                  shape: RoundedRectangleBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(100, 58),
                ),
                onPressed: () {
                  _focusNode?.unfocus();
                  context.read(settings).setProxy = _query;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
