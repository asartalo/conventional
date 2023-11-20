import 'package:git_hooks/git_hooks.dart';
// import 'dart:io';

void main(List arguments) {
  // ignore: omit_local_variable_types
  final Map<Git, UserBackFun> params = {
    Git.commitMsg: commitMsg,
    Git.preCommit: preCommit
  };
  GitHooks.call(arguments as List<String>, params);
}

Future<bool> commitMsg() async {
  // var commitMsg = Utils.getCommitEditMsg();
  // if (commitMsg.startsWith('fix:')) {
  //   return true; // you can return true let commit go
  // } else {
  //   print('you should add `fix` in the commit message');
  //   return false;
  // }
  return true;
}

Future<bool> preCommit() async {
  // try {
  //   ProcessResult result = await Process.run('dartanalyzer', ['bin']);
  //   print(result.stdout);
  //   if (result.exitCode != 0) return false;
  // } catch (e) {
  //   return false;
  // }
  return true;
}
