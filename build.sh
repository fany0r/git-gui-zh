#!/bin/bash
echo "GIT_VERSION: $1"

if [ "x$1" == "x" ]; then
  echo "Missing git version"
  exit 1
fi

gitver="$1"
tarfile="v$gitver.tar.gz"

if [ ! -f "$tarfile" ]; then
  curl -L -O "https://github.com/git-for-windows/git/archive/refs/tags/$tarfile"
  # https://github.com/git-for-windows/git/archive/refs/tags/v2.47.0.windows.2.tar.gz
fi

tar xf "$tarfile"

dir="git-$gitver"
outdir="build"

modir="$outdir/mingw64/share/locale/zh_CN/LC_MESSAGES"
guidir="$outdir/mingw64/share/git-gui/lib/msgs"
gitkdir="$outdir/mingw64/share/gitk/lib/msgs"

mkdir -p $modir
mkdir -p $guidir
mkdir -p $gitkdir

msgfmt -o "$modir/git.mo" ./$dir/po/zh_CN.po
msgfmt --tcl -l zh_CN -d "$guidir" ./$dir/git-gui/po/zh_cn.po
msgfmt --tcl -l zh_CN -d "$gitkdir" ./$dir/gitk-git/po/zh_cn.po

zipname="build-$gitver.zip"

if [ -d "$outdir" ]; then
  pwd & ls -l
  rm -rf "$zipname"
  
  if command -v zip &>/dev/null; then
    cd "$outdir"
    zip -r -y "../$zipname" .
    cd ..
  else
    # 如果 zip 不可用，尝试使用 PowerShell Core
    if command -v pwsh &>/dev/null; then
      pwsh -Command \
        '& { param([String]$sourceDirectoryName, [String]$destinationArchiveFileName, [Boolean]$includeBaseDirectory); Add-Type -A "System.IO.Compression.FileSystem"; Add-Type -A "System.Text.Encoding"; [IO.Compression.ZipFile]::CreateFromDirectory($sourceDirectoryName, $destinationArchiveFileName, [IO.Compression.CompressionLevel]::Fastest, $includeBaseDirectory, [System.Text.Encoding]::UTF8); exit !$?;}' \
        -sourceDirectoryName "$outdir" \
        -destinationArchiveFileName "$zipname" \
        -includeBaseDirectory '$false'
      if [ $? -ne 0 ]; then
        echo "PowerShell zip failed"
        exit $?
      fi
    else
      echo "Neither zip nor PowerShell is available for compression"
      exit 1
    fi
  fi
fi

if [ -f "$zipname" ]; then
  echo "Zip file created: $zipname"
  echo "ZIP_FILE=$zipname" >> $GITHUB_ENV
  pwd
  ls -l
else
  echo "Error: Zip file not created: $zipname"
  ls -R
  exit 1
fi


# 清理临时文件
rm -rf "$outdir"
rm -rf "$dir"
# rm -rf "$tarfile" # 可选：保留 tar 文件以便重复使用