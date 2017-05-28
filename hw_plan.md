# Ceph Reboot



## Plan A

### Node 1 (Ceph-Main)
*   __[ASUS J1900-C](https://tw.buy.yahoo.com/gdsale/gdpcdiy.asp?gdid=5371594)__
*   __[Micron Crucial 8G DDR3-1600](https://www.sinya.com.tw/prod/55872)__
*   WD Caviar RED 2T (osd.0)

### Node 2 (MS05)
*   Pine A64 2G
*   WD Caviar GREEN 2T (osd.1)

### Node 3 (MS06)
*   Raspberry Pi3
*   __500G HDD__(osd.2)

### Sub
*   total capacity: __2.25T__ (4.5T/2)
*   total cost: __NT$4089__ (1990+1499+600)

## Plan B

### Node 1 (Ceph-Main)
*   __[ASRock J3160-ITX](http://coolpc.com.tw/evaluate.php)__
*   
*   WD Caviar RED 2T (osd.0)
*   WD Caviar GREEN 2T (osd.1)

### Node 2 (MS05)
*   Pine A64 2G
*   HGST Touro 2T(osd.2)

### Sub
*   total capacity: __3T__ (6T/2)
*   total cost: __NT$4389__ (2890+1499)

## Plan C

### Node 1 (Ceph-Main)
*   __[ASRock J3455-ITX](https://detail.tmall.com/item.htm?id=543864963216)__
*   Transcend DDR3-1600L 4G x2
*   WD Caviar RED 2T (osd.0)
<!-- *   __[UPMOST SC310 PCI-e 2-Port SATA](https://tw.mall.yahoo.com/item/p090454948955)__  -->
*   WD Caviar GREEN 2T (osd.1)
<!-- *   __[SilverStone ECP01 Power Converter](https://tw.mall.yahoo.com/item/p077463381107)__ -->

### Node 2 (MS07)
*   __[Banana PI M3(BPI-M3)](https://world.taobao.com/item/523720083352.htm)__
*   __Heat Sink__
*   __[BPi to SATA Cable](https://world.taobao.com/item/38416714414.htm)__
*   WD 2.5' 1T

### Node 3 (MS05)
*   Pine A64 2G (mds.MS05)

### Ref. Hardware
*   Play-PC-NB2
    *   __[Micron Crucial 8G DDR3-1600 x2](https://www.sinya.com.tw/prod/55872)__

### Sub
*   total capacity: __2.5T__ (5T/2)
*   total cost: __NT$7732__ (2558+1499*   2+2104+30+42)


--------------------------------------------------------------------------------

## Summary

|                       | Plan A    | Plan B    | Plan C    |
|---------              | ------    | ------    |------     |
| CPU Peformance        | 1877      | 1836      | 2132      |
| cost                  | 4089      | 4389      | 7732      |
| capccity              | 2.25T     | 3T        | 2.5T      |
| power                 | +15W      | -3W       | +15W      |
| statablity            | 3/5       | 4/5       | 4/5       |
| est. Disk Peformance  | 12 M/s    | 10 M/s    | 20+ M/s   |
