<?php

$mediaStatus = trim(shell_exec('playerctl status 2>&1'));
if ($mediaStatus !== 'No players found') {
	$mediaContent = trim(`playerctl metadata --format '"{{title}}" by {{artist}}'`);
	$mediaStatus = "$mediaStatus $mediaContent";
}

$timezone = trim(`timedatectl`);
$brightnessCurrent = trim(`brightnessctl get`);
$brightnessMax = trim(`brightnessctl max`);

$timezone = preg_match('%Time zone: ([\w/]+)%', $timezone, $matches);
$timezone = $matches[1];
date_default_timezone_set($timezone);

$volume = trim(`wpctl get-volume @DEFAULT_SINK@`);
$volume = str_replace('Volume: ', '', $volume);

$brightnessCurrent = trim($brightnessCurrent);
$brightnessMax = trim($brightnessMax);
$brightnessPercent = round($brightnessCurrent / $brightnessMax * 100);

$batteryFile = '/sys/class/power_supply/BAT0/capacity';
$battery = file_exists($batteryFile) ? trim(`cat $batteryFile`) : 'None';

$time = date('Y-m-d h:i:s a');

$output = [
	"VOL $volume",
	"SCR $brightnessPercent",
	"BAT $battery",
	$time,

];
if ($mediaStatus) array_unshift($output, $mediaStatus);
echo implode(' | ', $output);
