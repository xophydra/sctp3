echo "== kernel"; uname -r
echo "== seccomp state of pid1"
grep -E 'Seccomp|NoNewPrivs|CapEff' /proc/1/status 2>&1
echo "== sctp module present on host (config)"; grep -E 'CONFIG_IP_SCTP' /boot/config-$(uname -r) 2>&1 | head -2
ls /usr/lib/modules/$(uname -r)/kernel/net/sctp/ 2>&1 | head -3
echo "== socket matrix, correct form"
python3 -c "
import socket,os
for fam,ty,proto,nm in ((2,1,132,'AF_INET/STREAM/IPPROTO_SCTP'),(2,5,132,'AF_INET/SEQPACKET/IPPROTO_SCTP'),(10,1,132,'AF_INET6/STREAM/SCTP'),(2,1,0,'AF_INET/STREAM/TCP'),(2,5,0,'AF_INET/SEQPACKET/raw0'),(12,1,0,'AF12/STREAM'),(2,1,133,'AF_INET/STREAM/IPPROTO_SCTP+1')):
  try:
    s=socket.socket(fam,ty,proto); print(nm,'OK fd',s.fileno()); s.close()
  except OSError as e: print(nm,'FAIL',e.errno,e.strerror)
print('after: modules sctp count', open('/proc/modules').read().count('sctp'))
print('after: protocols SCTP count', open('/proc/net/protocols').read().count('SCTP'))
print('after: /proc/sys/net/sctp exists', os.path.exists('/proc/sys/net/sctp'))
" 2>&1
echo "== stack exercise on AF_INET/SEQPACKET/SCTP"
python3 -c "
import socket
try:
  s=socket.socket(2,5,132); s.bind(('127.0.0.1',0)); print('bind OK',s.getsockname())
  s.listen(1); print('listen OK')
  c=socket.socket(2,5,132); c.connect(s.getsockname()); print('connect OK')
  a,ad=s.accept(); print('accept OK',ad)
  c.send(b'ping'); print('send OK, recv',a.recv(8))
  for lvl,opt,nm in ((132,1,'SCTP_AUTH_REQUIRED'),(132,5,'SCTP_INITMSG'),(132,2,'SCTP_PEER_ADDR_PARAMS'),(132,17,'SCTP_AUTH_CHUNK'),(132,18,'SCTP_AUTH_KEY')):
    try: c.setsockopt(lvl,opt,1); print('setsockopt',nm,'OK')
    except OSError as e: print('setsockopt',nm,'ERR',e.errno,e.strerror)
  try: print('getsockname',c.getsockname())
  except OSError as e: print('getsockname ERR',e.errno)
  print('modules now', open('/proc/modules').read().count('sctp'))
except OSError as e: print('stack ERR',e.errno,e.strerror)
" 2>&1
echo "== sysctls after"
ls /proc/sys/net/sctp/ 2>&1 | head -6
for f in addip_enable auth_enable max_number default_max_retrans; do printf '%s=' "$f"; cat /proc/sys/net/sctp/$f 2>&1; done
echo "== ip_options correct form"
python3 -c "
import socket,struct
s=socket.socket(2,1)
for lvl,opt,nm,args in ((0,3,'IP_OPTIONS',bytes([7,4,0,0])),(0,3,'IP_OPTIONS_40',bytes(40)),(0,5,'IP_SRC_ROUTE',bytes([7,4,0,0,0,0,0,0])),(0,2,'IP_TOS',1),(0,4,'IP_TTL',64)):
  try: s.setsockopt(lvl,opt,args); print('setsockopt',nm,'OK')
  except OSError as e: print('setsockopt',nm,'ERR',e.errno,e.strerror)
" 2>&1
echo "== done"
