#!/bin/bash

baseDir=/raw-subtitles
ytUrl=https://www.youtube.com/channel

mkdir -p $baseDir/indexes
mkdir -p $baseDir/channels

while read line; do

	folder=$(echo $line | cut -d',' -f1)
	channel=$(echo $line | cut -d',' -f2)
	name=$(echo $line | cut -d',' -f3)
	
	curDir=$baseDir/channels/$folder
	mkdir -p $curDir && cd $curDir
	rm -fr tmp && mkdir tmp

	youtube-dl -f 18 \
		--max-downloads 4\
		--playlist-end 100 \
		-i $ytUrl/$channel

	
	# generate subtitle
	ls -tr *.mp4 > mp4s.txt
	while read mp4; do
		vid=$(echo $mp4 | rev | cut -c5-15 | rev )
		nvid=_$vid
		if [ ! -f $nvid.srt ]; then
			autosub -F srt -S zh-CN -D zh-CN -o "$nvid.srt" "$mp4"
			cat "$nvid.srt" | awk 'NR%4==3' > "$nvid.text"
		fi

		echo $mp4 > tmp.txt
		grep -v -- $vid names.txt >> tmp.txt
		mv tmp.txt names.txt 		
	
		# remove duplicated	
		if [ -f tmp/$nvid ]; then
			rm $(cat tmp/$nvid)	
		fi
		echo $mp4 > tmp/$nvid
	done < mp4s.txt


	# cleanup
	ls -t *.mp4 | sed -n '5,$p' > old.txt
	while read line; do
		rm -fr "$line"
	done < old.txt
	

	# generate page
	cd $baseDir
	index=$baseDir/indexes/$folder.md
	echo -e "### 《$name》原始字幕/文字稿\n---" > $index
	echo "#####  链接：[最终字幕/文字稿（已手动修正）](https://github.com/gfw-breaker/$folder-subtitles)"  >> $index
	echo "| 节目名称 | 视频/音频 | 原始字幕 | 原始文字稿" >> $index
	echo "|---|---|---|---|"  >> $index
	
	while read line; do
		vid=$(echo $line | rev | cut -c5-15 | rev )
		nvid=_$vid
		title=$(echo $line | rev | cut -c17- | rev)
		echo "| $title | [下载](https://y2mate.com/zh-cn/search/$vid) | [下载](../channels/$folder/$nvid.srt?raw=true) | [下载](../channels/$folder/$nvid.text?raw=true) | " >> $index
	done < $curDir/names.txt

done < $baseDir/channels.csv

# git push
cd $baseDir
git pull
git add indexes/*.md
git add */*/*.srt
git add */*/*.text
git commit -a -m 'break the wall'
git push


