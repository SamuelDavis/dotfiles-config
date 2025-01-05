<?php

$mediaStatus = trim(`playerctl status 2>&1` ?? '');
if ($mediaStatus !== 'No players found') {
	$mediaContent = trim(`playerctl metadata --format '"{{title}}" by {{artist}}'` ?? '');
	$mediaStatus = "$mediaStatus $mediaContent";
}

$volume = trim(`wpctl get-volume @DEFAULT_SINK@` ?? '');
$volume = str_replace('Volume: ', '', $volume);

$brightnessCurrent = trim(`brightnessctl get` ?? '');
$brightnessMax = trim(`brightnessctl max` ?? '');
$brightnessPercent = round($brightnessCurrent / $brightnessMax * 100);

$batteryFile = '/sys/class/power_supply/BAT0/capacity';
$battery = file_exists($batteryFile) ? trim(`cat $batteryFile` ?? '') : null;

$time = date('Y-m-d h:i:s a');

$output = [
	"VOL $volume",
	"SCR $brightnessPercent",
	"BAT $battery",
	$time,

];
if ($mediaStatus) array_unshift($output, $mediaStatus);
echo implode(' | ', $output);
