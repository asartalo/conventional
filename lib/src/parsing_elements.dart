// ignore_for_file: type_annotate_public_apis, public_member_api_docs
import 'package:petitparser/petitparser.dart';

final newLine = Token.newlineParser();
final blankLine = (newLine & newLine).map((parsed) => 'BLANKLINE');
final wholeWord = word().plus().flatten().trim();
final number = digit().plus().trim().flatten();
final d2 = digit().repeat(2).flatten();
final d4 = digit().repeat(4).flatten();
final colon = char(':');
