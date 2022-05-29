package main

import (
	"bufio"
	"fmt"
	"encoding/json"
    "log"
    "net"
    "time"
    "github.com/google/gopacket/layers"
    "github.com/google/gopacket"
    "github.com/google/gopacket/pcap"
	"os"
)

type Tuple struct {
	SrcIP		string	
	SrcPort		int
	DstIP		string	
	DstPort		int
	Protocol	int
}

var (
	device       string = "br0"
    snapshot_len int32 = 65535
    promiscuous  bool  = false
    err          error
    timeout      time.Duration = 30 * time.Second
    handle       *pcap.Handle
    buffer       gopacket.SerializeBuffer
    options      gopacket.SerializeOptions
)

func genPkt(pkt Tuple) []byte {
    // Send raw bytes over wire
    rawBytes := []byte{'A', 'b', 'C'}

    // This time lets fill out some information
	// 填充数据包信息
    ethernetLayer := &layers.Ethernet{
        EthernetType: 0x0800,
        SrcMAC:       net.HardwareAddr{0xFF, 0xAA, 0xFA, 0xAA, 0xFF, 0xAA},
        DstMAC:       net.HardwareAddr{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
    }
	ipLayer := &layers.IPv4{
        Protocol: 17,
        Flags:    0x0000,
        IHL:      0x45,
        TTL:      0x80,
        Id:       0x1234,
        Length:   0x001e,
        SrcIP:    net.ParseIP(pkt.SrcIP),
        DstIP:    net.ParseIP(pkt.DstIP),
    }
    udpLayer := &layers.UDP{
        SrcPort: layers.UDPPort(pkt.SrcPort),
        DstPort: layers.UDPPort(9998),
        Length:  0x000a,
    }
   
    // And create the packet with the layers
    buffer = gopacket.NewSerializeBuffer()
    gopacket.SerializeLayers(buffer, options,
        ethernetLayer,
        ipLayer,
        udpLayer,
        gopacket.Payload(rawBytes),
    )
    outgoingPacket := buffer.Bytes()
	return outgoingPacket
}


func loadData() []Tuple{
	var pkts []Tuple
	file, err := os.Open("dat.json");
	if err != nil {
		fmt.Println("failed to open")
		return pkts
	}
	defer file.Close()
	reader := bufio.NewReader(file)

	for {
		line, err := reader.ReadBytes('\n');
		if err != nil {
			break
		}
		var pkt Tuple
		err = json.Unmarshal(line, &pkt)
		if err != nil {
			fmt.Println("json unmarshal error:", err)
		}
		pkts = append(pkts, pkt)
	}
	return pkts
}

func main() {
	var pkts []Tuple
	pkts = loadData()

	// 接管网卡
	handle, err = pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
	if (err != nil) {
		log.Fatalf("Can't open device: %s\n", err);
	}

	// 每隔1s，发送数据包
    for {
		for i := 0; i < len(pkts); i++ {
			outgoingPacket := genPkt(pkts[i])
			// time.Sleep(time.Second)
			err = handle.WritePacketData(outgoingPacket)
			if err != nil {
				log.Fatal(err)
			}
		}
    }

    handle.Close()
}
