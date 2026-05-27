# Merge dev-https into dev — pubspec.lock conflict resolved

## The error

```
$ git merge dev-https
error: Merging is not possible because you have unmerged files.
hint: Fix them up in the work tree, and then use 'git add/rm <file>'
fatal: Exiting because of an unresolved conflict.
```

`git merge dev-https` had already been started in a previous session
and was sitting half-finished with one unresolved conflict:

```
.git/MERGE_HEAD   = b0372c9   (= dev-https tip)
unmerged file     = flutter_app/pubspec.lock
```

Re-running `git merge dev-https` won't start a new merge while the
in-progress one is still open — hence the error.

## Resolution

`pubspec.lock` is auto-generated from `pubspec.yaml`, so hand-merging
it is the wrong fix — it must match whatever `flutter pub get`
produces from the merged `pubspec.yaml`.

```powershell
git checkout --theirs flutter_app/pubspec.lock   # take dev-https version
cd flutter_app
flutter pub get                                   # regenerate canonically
git add flutter_app/pubspec.lock
git commit --no-edit                              # finish the merge
```

The `flutter pub get` resolved cleanly ("Got dependencies!"), so the
two branches' `pubspec.yaml` files were compatible — the lockfile was
just stale relative to the merged manifest.

## Result

`dev` now contains the merge:

```
*   11082f1 Merge branch 'dev-https' into dev
|\
| * b0372c9 delete illegal words in json
| * 2e2a460 …
```

No other files were conflicted; `git diff --name-only --diff-filter=U`
is now empty.

## User prompt (verbatim)

> git merge dev-https
> I get error when execute above.
> plz solve it
