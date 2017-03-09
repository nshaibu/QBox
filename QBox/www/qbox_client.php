#!/usr/local/bin/php
 
<?php
error_reporting(E_ALL);

/* Get the port for the WWW service. */
//$service_port = getservbyname('www', 'tcp');
$service_port=4030;
/* Get the IP address for the target host. */
//$address = gethostbyname('www.example.com');
$address='localhost';
/* Create a TCP/IP socket. */
$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
if ($socket === false) {
    echo "socket_create() failed: reason: " . socket_strerror(socket_last_error()) . "\n";
} else {
    echo "OK.\n";
}

echo "Attempting to connect to '$address' on port '$service_port'...";
$result = socket_connect($socket, $address, $service_port);
if ($result === false) {
    echo "socket_connect() failed.\nReason: ($result) " . socket_strerror(socket_last_error($socket)) . "\n";
} else {
    echo "OK.\n";
}

if ($_GET['submit'] == "submit"){
	$in = $_GET['cmd'];
}

echo $in;

socket_write($socket, $in, strlen($in));

/*while ($out = socket_read($socket, 2048)) {
    $_GET['cmd']=$out;
}
*/
$out = socket_read($socket, 2048);

socket_close($socket);
?>

