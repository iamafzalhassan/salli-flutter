import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'locale_keys.dart';

extension DateLabels on BuildContext {
  String dateLabel(DateTime date) => DateFormat.yMMMd(locale.toLanguageTag()).format(date.isUtc ? DateTime(date.year, date.month, date.day) : date);

  String greeting() => switch (TimeOfDay.now().hour) {
    < 12 => this.tr(LocaleKeys.homeGreetingMorning),
    < 17 => this.tr(LocaleKeys.homeGreetingAfternoon),
    _ => this.tr(LocaleKeys.homeGreetingEvening),
  };

  String momentLabel(DateTime moment) => DateUtils.isSameDay(moment.toLocal(), DateTime.now()) ? timeLabel(moment) : dayLabel(moment);

  String monthLabel(DateTime month) => DateFormat.yMMMM(locale.toLanguageTag()).format(month);

  String timeLabel(DateTime moment) => DateFormat.jm(locale.toLanguageTag()).format(moment.toLocal());

  String dayLabel(DateTime moment) {
    final local = moment.toLocal();
    final days = DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(local)).inDays;
    return switch (days) {
      0 => this.tr(LocaleKeys.dateToday),
      1 => this.tr(LocaleKeys.dateYesterday),
      _ => DateFormat.yMMMd(locale.toLanguageTag()).format(local),
    };
  }
}
