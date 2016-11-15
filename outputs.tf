output "HOBLITT_COM_IP" {
    value = "${aws_eip.hoblitt-com.public_ip}"
}
