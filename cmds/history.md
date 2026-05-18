    1  ls
    2  cd ..
    3  ls
    4  cd /
    5  ls
    6  cd ~
    7  ls
    8  mkdir work
    9  rm -rf work
   10  ls
   11  git clone https://gitlab.com/aiti3/backend.git
   12  whoami
   13  node --version
   14  cat /etc/centos-release
   15  cat /etc/os-release
   16  sudo dnf install -y git
   17  git --version
   18  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
   19  source ~/.bashrc
   20  nvm --version
   21  nvm install 20
   22  node --version
   23  npm --version
   24  git clone https://gitlab.com/aiti3/backend.git
   25  git clone https://aiti.jjy:glpat-_Lu3PUIonZTsIK1ssvwst2M6MQpvOjEKdTptcmdxbg8.01.1706fr2xr@gitlab.com/aiti3/backend.git
   26  sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
   27  sudo dnf -qy module disable postgresql
   28  sudo dnf install -y postgresql15 postgresql15-server postgresql15-contrib
   29  sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
   30  sudo systemctl enable --now postgresql-15
   31  sudo systemctl status postgresql-15
   32  sudo -u postgres psql
   33  npm run migration:run
   34  sudo -u postgres psql
   35  sudo systemctl restart postgresql-15
   36  npm run migration:status
   37  sudo -u postgres psql
   38  sudo systemctl restart postgresql-15
   39  sudo firewall-cmd --permanent --add-port=5432/tcp
   40  sudo firewall-cmd --reload
   41  npm run migration:status
   42  npm run migration:run
   43  npm run seed
   44  npm run start:dev
   45  sudo dnf groupinstall -y "Development Tools"
   46  sudo dnf install -y cmake gcc gcc-c++ make git
   47  git clone https://github.com/ggerganov/llama.cpp.git
   48  cd llama.cpp
   49  cmake -B build
   50  cmake --build build --config Release -j$(nproc)
   51  ./build/bin/llama-server   --model "hf://bartowski/Llama-3.2-3B-Instruct-GGUF/Llama-3.2-3B-Instruct-Q4_K_M.gguf"   --port 8080
   52  ls
   53  ./build/bin/llama-server -hf ggml-org/gemma-3-1b-it-GGUF
   54  nohup ./build/bin/llama-server -hf ggml-org/gemma-3-1b-it-GGUF  > llama.log 2>&1 &
   55  ps aux | grep llama-server
   56  tail -f llama.log
   57  ail -f llama.log
   58  tail -f llama.log
   59  sudo nano /var/lib/pgsql/15/data/postgresql.conf
   60  sudo vi /var/lib/pgsql/15/data/postgresql.conf
   61  sudo nano /var/lib/pgsql/15/data/pg_hba.conf
   62  sudo vi /var/lib/pgsql/15/data/pg_hba.conf
   63  sudo systemctl restart postgresql-15
   64  sudo firewall-cmd --permanent --add-port=5432/tcp
   65  sudo firewall-cmd --reload
   66  sudo dnf install -y firewalld
   67  sudo systemctl enable --now firewalld
   68  sudo firewall-cmd --permanent --add-port=5432/tcp
   69  sudo firewall-cmd --reload
   70  sudo firewall-cmd --permanent --add-port=5000/tcp
   71  sudo firewall-cmd --reload
   72  timedatectl
   73  sudo timedatectl set-timezone Asia/Tokyo
   74  timedatectl
   75  sudo -u postgres psql
   76  sudo systemctl status postgresql-15
   77  sudo tail -f /var/lib/pgsql/15/data/log/postgresql-*.log
   78  sudo nano /var/lib/pgsql/15/data/postgresql.conf
   79  sudo dnf install -y nano
   80  sudo nano /var/lib/pgsql/15/data/postgresql.conf
   81  sudo nano /var/lib/pgsql/15/data/pg_hba.conf
   82  sudo systemctl restart postgresql-15
   83  exit
   84  ls
   85  cd backend
   86  ls
   87  ll
   88  cd ..
   89  df
   90  git clone
   91  git clone https://gitlab.com/aiti3/frontend/
   92  git clone https://tonygonzales:glpat-1Ux8Fv1ZAK_GrmGX-IklsmM6MQpvOjEKdTptcWVjYQ8.01.170xzu32o@gitlab.com/aiti3/frontend.git
   93  sudo firewall-cmd --permanent --add-service=http
   94  sudo firewall-cmd --permanent --add-service=https
   95  sudo firewall-cmd --reload
   96  sudo yum install epel-release -y
   97  sudo yum install nginx -y
   98  cd /etc/nginx
   99  ls
  100  cd conf.d
  101  ls
  102  nano app.conf
  103  sudo nginx -t
  104  sudo systemctl reload nginx
  105  sudo systemctl start nginx
  106  sudo systemctl status nginx
  107  sudo nginx -t
  108  cd /etc/nginx
  109  ls
  110  nano nginx.conf
  111  nano conf.d/app.conf 
  112  sudo nginx -t
  113  sudo systemctl restart nginx
  114  sudo ss -tlnp | grep node
  115  sudo tail -f /var/log/nginx/error.log
  116  nano conf.d/app.conf 
  117  sudo nginx -t
  118  sudo systemctl restart nginx
  119  sudo tail -f /var/log/nginx/error.log
  120  sudo setsebool -P httpd_can_network_connect 1
  121  sudo systemctl reload nginx
  122  nano conf.d/app.conf 
  123  nginx -t
  124  systemctl restart nginx
  125  systemctl status nginx
  126  sudo tail -f /var/log/nginx/error.log
  127  nano conf.d/app.conf 
  128  sudo tail -f /var/log/nginx/error.log
  129  nginx -t
  130  sudo nano conf.d/app.conf 
  131  sudo firewall-cmd --permanent --add-port=4000/tcp
  132  sudo firewall-cmd --reload
  133  nano conf.d/app.conf 
  134  systemctl restart nginx
  135  sudo tail -f /var/log/nginx/error.log
  136  nano conf.d/app.conf 
  137  systemctl restart nginx
  138  nano conf.d/app.conf 
  139  nginx -t
  140  systemctl restart nginx
  141  nano conf.d/app.conf 
  142  curl -Lv --max-redirs 6 http://172.86.121.43/luma/ 2>&1 | grep -E "< HTTP|Location|> GET"
  143    nginx -T 2>/dev/null | grep -E "include|return|rewrite|redirect"
  144  curl -Lv --max-redirs 6 http://172.86.121.43/luma/ 2>&1 | grep -E "< HTTP|Location|> GET"
  145  claude
  146  git pull
  147  cd User
  148  node -v
  149  npm install
  150  npm run dev
  151  cd Admin
  152  npm install
  153  npm run dev
  154  cd frontend
  155  git pull
  156  cd /Admin && npm run dev & cd /User && npm run dev
  157  cd /root/frontend/Admin && npm run dev & cd /root/frontend/User && npm run dev
  158  cd frontend
  159  cd /root/frontend
  160  git pullss -tulnp
  161  ss -tulnp
  162  cd /root/frontend/Admin && npm run dev & cd /root/frontend/User && npm run dev
  163  cd backend
  164  nano .env
  165  pm2 start npm --name "nest-backend" -- run start:dev
  166  npm install -g pm2
  167  pm2 start npm --name "nest-backend" -- run start:dev
  168  pm2 status
  169  pm2 logs nest-backend
  170  ps
  171  ps -a
  172  kill $(lsof -t -i:5000)
  173  lsof -i:5000
  174  ss -tlnp | grep 5000
  175  kill 147818
  176  pm2 restart nest-backend
  177  pm2 logs nest-backend
  178  pm2 stop nest-backend
  179  ss -tlnp | grep 5000
  180  kill 147818
  181  ss -tlnp | grep 5000
  182  kill -9 147818
  183  ss -tlnp | grep 5000
  184  pm2 start npm --name "nest-backend" -- run start:dev
  185  pm2 --help
  186  pm2 delete all
  187  pm2 --help
  188  pm2 start npm --name "nest-backend" -- run start:dev
  189  pm2 logs nest-backend
  190  cd ..
  191  cd frontend
  192  ls
  193  cd Admin
  194  pm2 start npm --name "luma" -- run dev
  195  cd ..
  196  cd User/
  197  pm2 start npm --name "chat" -- run dev
  198  exit
  199  pm2 logs nest-backend
  200  ss -tlnp | grep 5000
  201  pm2 status 
  202  cat /var/log/nginx/error.log | tail -50
  203  nano /etc/nginx/conf.d/app.conf 
  204  nginx -t
  205  systemctl restart nginx
  206  ps aux | grep nohup
  207  ss -tlnp | grep node
  208  ps aux | grep llama-server
  209  npm test
  210  node --version
  211  which npx
  212  npm run migration:status
  213  npm run migration:run
  214  npm install
  215  git pull
  216  git config user.email "aiti.jjy@atomicmail.io"
  217  git config user.name "aiti jjy"
  218  node -version
  219  source ~/.bashrc 
  220  node --version
  221  git push
  222  node --version
  223  git commit -m "Update lint-staged version and adjust dependencies in package.json and package-lock.json"
  224  git push
  225  npm run start:dev
  226  ls
  227  cd backend
  228  ps | aux
  229  ls
  230  cd pg
  231  mkdir pg
  232  cd pg
  233  Activate the web console with: systemctl enable --n
  234  dnf download --resolve   postgresql15-server postgresql15-contrib   patroni   etcd   haproxy   pgbouncer
  235  nf download --resolve   postgresql15-server postgresql15-contrib   patroni   etcd   haproxy \
  236  dnf download --resolve   postgresql15-server postgresql15-contrib   patroni   etcd   haproxy \
  237  apt-get download   postgresql-15 postgresql-client-15 postgresql-contrib-15   patroni python3-patroni   etcd etcd-client   haproxy   pgbouncer
  238  dnf download --resolve postgresql15-server postgresql15-contrib patroni etcd haproxy pgbouncer
  239  Last metadata expiration check: 2:38:16 ago on Mon 18 May 2026 12:58:17 PM JST.
  240  No package etcd available.
  241  Exiting due to strict setting.
  242  ETCD_VER=v3.5.13
  243  curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o etcd-${ETCD_VER}-linux-amd64.tar.gz
  244  dnf download --resolve postgresql15-server postgresql15-contrib patroni haproxy pgbouncer
  245  ls
  246  dnf info patroni
  247  exit
  248  service status
  249  systemctl list-units --type=service --state=running
  250  history
  251  ls
  252  cd vfls
  253  history > history.md
