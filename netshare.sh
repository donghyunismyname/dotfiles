while true; do
    sudo pppd user "netshare" password 0000 call netshare \
        pty "nc 192.168.49.1 8181; killall pppd"
    sleep 2
done

