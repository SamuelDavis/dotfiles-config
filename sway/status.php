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

$battery = '/sys/class/power_supply/BAT0/capacity';
$battery = file_exists($battery) ? trim(`cat $battery` ?? '') : null;
$status = '/sys/class/power_supply/BAT0/status';
$status = file_exists($status) ? trim(`cat $status` ?? '') : null;

if ($status === 'Charging') $status = '+';
elseif ($status === 'Discharging') $status = '-';
elseif ($status === 'Not charging') $status = ' ';
else $status = " ($status)";

$time = date('Y-m-d h:i:s a');

$output = [
	"VOL $volume",
	"SCR $brightnessPercent",
	"BAT $battery$status",
	$time,
];
if ($mediaStatus) array_unshift($output, $mediaStatus);
echo implode(' | ', $output);
