KEY="mykey"
KEY2="plexkey"
CHAINID="highbury_710-1"
MONIKER="blackfury-validator"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
#TRACE="--trace"
TRACE=""

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Reinstall daemon
rm -rf ~/.black*
make install

# Set client config
black config keyring-backend $KEYRING
black config chain-id $CHAINID

# if $KEY exists it should be deleted
black keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO
black keys add $KEY2 --keyring-backend $KEYRING --algo $KEYALGO

# Set moniker and chain-id for Black (Moniker can be anything, chain-id must be an integer)
black init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to ablack
cat $HOME/.black/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["evm"]["params"]["evm_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json
cat $HOME/.black/config/genesis.json | jq '.app_state["inflation"]["params"]["mint_denom"]="ablack"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json

# Change voting params so that submitted proposals pass immediately for testing
cat $HOME/.black/config/genesis.json| jq '.app_state.gov.voting_params.voting_period="7200s"' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json


# disable produce empty block
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.black/config/config.toml
  else
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.black/config/config.toml
fi

if [[ $1 == "pending" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.black/config/config.toml
      sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.black/config/config.toml
  else
      sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "2s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.black/config/config.toml
      sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.black/config/config.toml
  fi
fi

# Allocate genesis accounts (cosmos formatted addresses)
black add-genesis-account $KEY 370446789000000000000ablack --keyring-backend $KEYRING
black add-genesis-account $KEY2 64808383230000000000000000ablack --keyring-backend $KEYRING

# Contributors
black add-genesis-account black1jl2zcz32npjgs88vd60xv5qan5rtzh4xena7na 10000000000000afury  				
black add-genesis-account black19umlsn9fc3ytfe9s3l9dez4z2ujjljqjj3lcu0 2500000000000afury  				
black add-genesis-account black1t0lzffhd5yhclj4pmhxp4h82nxfr08c58ezysy 825000000000afury  				
black add-genesis-account black120fza5vukwmaksphtqesrh4kqxf8er6emtjgvd 4455000000000afury  				
black add-genesis-account black1d03ppywn369qzajeuqs0dge29rchxtearzwxea 825000000000afury  				
black add-genesis-account black1e6m3jymsgetz5vyvkvujejqufanpq8mgj7d0ph 2310000000000afury  				
black add-genesis-account black1y0lufpa3yfnwrjk5lfz3zcl9hq6stmdhzy0fv3 353571900000afury  				
black add-genesis-account black1f02wg3dawqdwjv7ak7e6vh2u6sjf5s26ftn5tv 2722500000000afury  				
black add-genesis-account black1ejtqghtlhauyqag8xphnkltvqjuxwl5s20htsw 353571075000afury  				
black add-genesis-account black1t2rkh00d000qzlyj2l2l8z5hy34a3e73ye6a5g 235714050000afury  				
black add-genesis-account black1vum9yv6gtd54kpgdhd37p5z097ngphlfdfqavc 235714050000afury  				
black add-genesis-account black136qxshkaf78ucuff4kdc8srw73k2x0adnatsnj 447386775000afury  				
black add-genesis-account black1xeve8vkkltsd9uzaqya78ywtspyc35hr00jrtz 94285950000afury  				
black add-genesis-account black1lldkcxprlhqknnal3w0wp2fe0mlhyzdckeqlcw 1178571075000afury  				
black add-genesis-account black1tz80tk5295jafft5njnvvxgnvcf63y3vpwwmkt 471428925000afury  				
black add-genesis-account black1al3k6rd4u550gcvfwd7akl032su2y2vt3fzj78 127285125000afury  				
black add-genesis-account black1jhpwxpadlx8ax429ljm5rrqm2pse4sgflnwv6p 247500000000afury  				
black add-genesis-account black1es9fu48yxwd9jdweaykjaf0fr7usw3x0anh989 165000000000afury  				
black add-genesis-account black1as8j8qhexvsc3sy0gxrfajuuggwar45c5kf4f6 99000000000afury  				
black add-genesis-account black158343p7g7qlw76ph5dzvtvk5tztegz3gl9va9k 132000000000afury  				
black add-genesis-account black1rq048x4ducr9nqze48g55x0q57e8lthxs5l0vz 136714050000afury  				
black add-genesis-account black1cwk4s0jtvt69mawaqsay2a9h20cgqd9hh8540l 2640000000000afury  				
black add-genesis-account black1wknw5glel2jekejuehn4auvfs7dhqf6z263hu3 66000000000afury  				
black add-genesis-account black14z8wsgf807e3hxuny5laaxtn0ytvcj9q9yl63c 330000000000afury  				
black add-genesis-account black1czemphdmk0j9vn6gspj454p24rs5jz4guafkwz 136714050000afury  				
black add-genesis-account black1hcgqp24ps3n09pk4ugu7tscj72q25r8r5hzasw 183386775000afury  				
black add-genesis-account black1gyvgpngr3saypgdud0etzj74q56vy97s5vva28 113142150000afury  				
black add-genesis-account black15wcg9d228whk85zf4rde7nypn09htc2g838v3j 183386775000afury  				
black add-genesis-account black10le9zwrp6x9t6xcg4ws2j8rsvggvktaj0zj8pv 282386775000afury  				
black add-genesis-account black1ssfpxgkzt4yj0unmzx0cmrx6mhm5kl0gfyj3kl 495000000000afury  				
black add-genesis-account black1w33lkcauxeyrq8nn3f6h9cgncxuxdrzm3smrzk 1060714050000afury  				
black add-genesis-account black1clwgp88d7aq2nhk5mmwk2w82t67n3fgksd4c22 154286250000afury  				
black add-genesis-account black17w74x9vrqq4a338ssh9y9r4m9s3f6zefa36pue 214286250000afury  				
black add-genesis-account black1kah8qvju0h5g0nslsfhvznrsw0jrhnryljkspk 428571750000afury  				
black add-genesis-account black1526zhyrd8fzdvzayct9yfnspsdp9uuqh8d977c 554530275000afury  				
black add-genesis-account black1d4ulqc7y3pqe5lxdwv0sl7cd9qnkjturwtyd4c 5357143500000afury  				
black add-genesis-account black19k85gsahz45qr86gn5t0ym7zac8nlm6vyf25hw 107143500000afury  				
black add-genesis-account black1qws9l50tvnmfx0hrek9500dzygv92rj4ww342f 214286250000afury  				
black add-genesis-account black14zeskm5s4yz75fd4r70m37u37wfzt9lpe8y0ak 28929000000afury  				
black add-genesis-account black1zy2usgrg4ywh7e3j8qychvxarp4y5shfph0hwj 21429000000afury  				
black add-genesis-account black1qksggyhumezsdmeelqrvhdyh2n6nshmuv8kz2l 214286250000afury  				
black add-genesis-account black1vmk950mvwakjef3qjjpcz9f28x3ah3q85l2vmm 42857250000afury  				
black add-genesis-account black1k03n5tcj6f7d6zkjp3xvl8h6hp05vprln8slk4 642857250000afury  				
black add-genesis-account black18zmgjqxa6d274achj6dmkdddys4453taytrz6m 642857250000afury  				
black add-genesis-account black1e5ag4a5wlckwzlz4wu87p6nxjp427zpmm2qq9p 214286250000afury  				
black add-genesis-account black1azg0gpgatmzr60mzya9d774eude263ef4u4n8a 214286250000afury  				
black add-genesis-account black1tluyekggnce4js7usrs0xk06528vg99r7smg7w 214286250000afury  				
black add-genesis-account black162cxa76zpvag4a05da0yhu69awfy35w8z3w0da 364286250000afury  				
black add-genesis-account black1kfr4wznhwelzhal8gc8es67tcx4g4tsyd3tx46 214286250000afury  				
black add-genesis-account black1qvesqkksz3nyrys5gvlryfj8zv90pz9q8zr0k4 642857250000afury  				
black add-genesis-account black1kml5p8et0j7zhqptxla74nf0gfsumcy70j23eh 2142857250000afury  				
black add-genesis-account black1nthsvkmqdl4qmeg0qh40s0jrjpquncdy4hckfh 3000000000000afury  				
black add-genesis-account black15y4xh9xj2lm9ll4usturv4qdugr5t0gnjtmhym 642857250000afury  				
black add-genesis-account black17xdjy3t0dtqhxzlk7dxmm32j7u7krfn3n3d37r 428571000000afury  				
black add-genesis-account black12l4ehyq5qzsmvapa5a8ls9sr65q8yf086sddvq 535714500000afury  				
black add-genesis-account black1fs2yal2cs89mqnn389ap3rh5z842llfhjxqns3 321428250000afury  				
black add-genesis-account black1mhv5w6up9ltlwe7ekgfpjhd0upn4f7umcsr2d7 964285500000afury  				

# Settlers/Helpers
black add-genesis-account black10h7ln638jkn55h5wfk2enyszhtv3nf3hn0czwg 21802986301afury  				
black add-genesis-account black13pqlfc4wesmfwg0mh224khsy9nrek2e357spsv 21774317808afury  				
black add-genesis-account black1dkmehpuc582evv2uq70kt0jptpehu3yr5ymv9p 20348060274afury  				
black add-genesis-account black122nwk3z6e4yeh4aj4xad3jmjy38h8jw8wlmmfm 4505134247afury  				
black add-genesis-account black13fdh9uey7t0hxvg825gdfdx346z7wsq2g7a8yx 218160663014afury  				
black add-genesis-account black1q97lwrj563g8ccfm6kl9zxndf860v60ejxfx0z 10902389041afury  				
black add-genesis-account black1unwqjxcwv95jfu3nt89ky8zqh39xpqvwj0789g 10887457534afury  				
black add-genesis-account black17parq8q75sr2cejrnrurtt7emfrc35a0skm9lm 5393260274afury  				
black add-genesis-account black199jfnv587vy4f63gn6t2t4dae42prk242cjfyw 30033830137afury  				
black add-genesis-account black1wackempnenwpzkywav6hnmdckqmthv30a7gata 3754378082afury  				
black add-genesis-account black1cnzy6g0vet3ykdhk2xgvkvc350d3gke4g72lh2 109016126027afury  				
black add-genesis-account black1r9764rmspkpy0qxx5myxq0kz90dukjna5lvjcl 7508158904afury  				
black add-genesis-account black16kgjjvhq9s07l639ylpc6sfp4cp6ze8hfswmrt 6006646575afury  				
black add-genesis-account black1fdgys6er5ak4syqgvc8uswcedjwknh6q0khh0u 21372361644afury  				
black add-genesis-account black1aqqskedu4zgmjqhpztjqzd7g8sfyzya2wn9pfe 22525073973afury  				
black add-genesis-account black18rp5vnjsswdazjvrdy2lj4cass9z29h5054c6r 6683939726afury  				
black add-genesis-account black16qt98ac36dtaaxr7axu67z68ue8pjpdcnw6whe 3769309589afury  				
black add-genesis-account black1q84cgldq5wf3am3tfuz2lzzx2azala64fnyhwm 30033830136afury  				
black add-genesis-account black145wnzde7ak68zm49yhgyc0apxpj6gwje8kvfhy 12095117808afury  				
black add-genesis-account black12u9t55uxfmkd8c4mzpeatvnjmyvuj5gent3z4d 113064953425afury  				
black add-genesis-account black1zejc6j533jjgzj64munsps257sa95282688yeq 13665315068afury  				
black add-genesis-account black1wypy5jw7xz0lkrz3ky538vr4e7seuvs9qsc6lr 3754378082afury  				
black add-genesis-account black1nk2rycxdgl5gxtd0hpncprwfp0lzeafwaf37tv 14085786301afury  				
black add-genesis-account black19frtd7huz6zrefnz3zl64z6q8r9wkt3paa7rge 10912542466afury  				
black add-genesis-account black1lqseqddsce3yu5wa7atf8feqqfyn3lcmgludn8 142502120548afury  				
black add-genesis-account black1kusnsv5evmtujdvr2hvr5chs9aen0gwydh944v 30033830137afury  				
black add-genesis-account black1elhw3cct0jgxvf2tw5yrrkc6u02shg8z5nea6x 4505134247afury  				
black add-genesis-account black19rn5vwga60kun3j38taxd26cm7lelgda5d6432 10978838356afury  				
black add-genesis-account black1htxf0fcfmyxyw8stjw38jz2s3muh3q6yslepur 10932252055afury  				
black add-genesis-account black169qmwy36jkhfzjdft3ptqqmj2zgkc3tv8dcywt 45050745205afury  				
black add-genesis-account black1zjvwyksf9vnk0dwxx3n8m9xlw6pglnf0a44jtv 3754378082afury  				
black add-genesis-account black1zurjhfcc5365dsy58unk6rnh9nltfsqqnhtg5h 15016915068afury  				
black add-genesis-account black134fwqahtfrg0zfr8x2su46fmrwme5mzw09n6sw 9325621918afury  				
black add-genesis-account black16k7xarsvqf7vv0qhu520rmarpt40g6jtzcng42 225252531507afury  				
black add-genesis-account black1nhhvjlq376f4gz6jvptsgv665vr3ss4qmzctxz 22525073972afury  				
black add-genesis-account black1wxvs6du63g8nmm5jpd3lzgwl6mqv0je9a2cy3e 11262536986afury  				
black add-genesis-account black17zjpts3cd35tesmwrunkynygyw7fuamsah7z7s 7133079452afury  				
black add-genesis-account black1ygqgkduw25g5uezflw4gnsm4n2yvawkmypfs4z 3754378082afury  				
black add-genesis-account black1zjydgdhd8uk4u29tq2e68j7kmqxrk3vsc9dfya 10901791781afury  				
black add-genesis-account black1x60g2u04z7jzdnjf3znfdcxa9ut5kufq2p7qp9 301947917808afury  				
black add-genesis-account black1lw0ruyesylglsu6m7dhefw4vfh8l8qweaaxetm 7508756164afury  				
black add-genesis-account black1r4w3ae4vuyatckn8pahvexl4kpvmndreu4jnc2 6006646575afury  				
black add-genesis-account black19j5upjz972gh24890tn6mpf4gzqdk09ajul5va 7508158904afury  				
black add-genesis-account black1cg3e7sfxkunmwgfsrqj3caju9aheuzlzw8nq9q 3754378082afury  				
black add-genesis-account black1ca6vj94jtn5v57prr826ncskrm0reateduhe5c 62281106849afury  				
black add-genesis-account black1ltk76ycjtz05j7ww7yznrr5cn5kz58za9lk7ge 15016915068afury  				
black add-genesis-account black1q5cddxnk7yqxc4fjfmnpxhygkcl3uw6s7y6efz 55920882191afury  				
black add-genesis-account black1r0afwj9krzmwsadjm6l6y7mlnq6l7px0mwte4j 8433315068afury  				
black add-genesis-account black1y26ufq905uy0s27ftujamqm5y8gdys8depwtsa 15016915068afury  				
black add-genesis-account black1w6pktm54f5zgq032xxacc3ylme98t560mcjfw8 7508756164afury  				
black add-genesis-account black1797slhn49lfmgn42vwjh6c6nrxq7k34nplujzd 22525073972afury  				
black add-genesis-account black122phsq2td9x3cv9pwszse3f69smfhhncxa778a 5255890411afury  				
black add-genesis-account black1vv6rsgxqh4hyxtt6dt4rmv4a93n7amjtqzzfnj 11370641096afury  				
black add-genesis-account black14cyvvq5nptglnjy2hg9ky6r26349v73nu7v0kl 31535342466afury  				
black add-genesis-account black17mrjke5ra03hqnh7tlk265xlj2asz9la8mndgy 30033830137afury  				
black add-genesis-account black1clseqnswluj79tzpng60sqhy3nf7pz0her3d0p 4505134247afury  				
black add-genesis-account black1ecm2vqdexfqy6kfpwdxxpl37vy289pmhj5slp2 3754378082afury  				
black add-genesis-account black1mgmcztfm8vvmfdmtlzk3n523vqm275j7846w9v 12331632877afury  				
black add-genesis-account black1nrye3zfvs7l438n6l56avnnzm6f00me8fmln2y 51474876713afury  				
black add-genesis-account black129kdy7qdk5r4qgrenqdd6ftjjuvcc3hqnm3u0z 295781113014afury  				
black add-genesis-account black10d4udrt2md9dzeqfaytkdhcd9utsmvxk6yf0w0 5255890411afury  				
black add-genesis-account black108gy2rzhx27jj96argmgpesvlj9ur6k87flc3n 10888652055afury  				
black add-genesis-account black1le8x5sn43nxn0sz5vuze509sea70sc6j3slwt3 5255890411afury  				
black add-genesis-account black1xvf0jjf9vkqz40rdlmm67cfhlzcwu520rrmyj6 15016915068afury  				
black add-genesis-account black168q4t94pxq97fy8vqenc6fx3znc7p8fes52vsx 3754378082afury  				
black add-genesis-account black1ty8uvzrhy5taa4auc9h9c02x0zfugu0jg2l6ts 70999315205afury  				
black add-genesis-account black1fzd65shhhkl7d3g2f5377fufd4k9adn258nctl 18019939726afury  				
black add-genesis-account black1dn8yt2pe62a9nz964vmj2pwreljxehxcfxm7dz 150168553424afury  				
black add-genesis-account black1yuqgnfuavv2wf6lpsr0w6wqed9d7grzal2nwpz 31925353425afury  				
black add-genesis-account black1yafjl2890r3gn38dc7ksp5r6vnfmy8ud2ecxau 125114082192afury  				
black add-genesis-account black1je5w89kn456ctj7fd3y4w4rf3f7klj6xkya4wj 30047567124afury  				
black add-genesis-account black1acd5nzld4f3c268cax90lk6he7m2w5ml09dvtg 15016317808afury  				
black add-genesis-account black154sksmrrrveqcdavk4ugyxmwlmdepdg0z8xdcp 30048164383afury  				
black add-genesis-account black1l52awqe7p8r9mmpm27c5avywt9urqdpdskn6fa 5255890411afury  				
black add-genesis-account black1fqtp07xjqwx2my5n42vcwufu6hc70zw4wwr9sf 3754378082afury  				
black add-genesis-account black18ws6vgl6w84qcs0wncup25va9ze88852cn5f5m 21023561644afury  				
black add-genesis-account black1wexz2r5g6rsphka9qqvsqsaalc4shw7hwwr3f0 41056268493afury  				
black add-genesis-account black1vu2p0zta4lg4fsdv777ugmajyvqrcsljwyhf2x 6006646575afury  				
black add-genesis-account black1lmw6wtyk0w6zg6jh05z4t5l7amvsalappdjuvs 30036219178afury  				
black add-genesis-account black12m90u3cetug08frawfu0p6jd96s354xdth00dw 15016915068afury  				
black add-genesis-account black14lkxkdlrmvv732vhygeev95tmerxec6akxdapz 45050745205afury  				
black add-genesis-account black1y2l7gnylqw3yp6u52tfgxuk0klx5uyms50tv9e 60067063014afury  				
black add-genesis-account black1gyv42pg4j790wlqt5muge7pe9d9xdw7rw0tt4d 3754378082afury  				
black add-genesis-account black1e5pkymea4jlcmnzvrycc97jfhdzcvpd3qqyrjz 45058509588afury  				
black add-genesis-account black15tmdfth2kmmaedag9sk7j0nw4herj39a3vzk89 15125019178afury  				
black add-genesis-account black145tk8ry9gzmr5jyn96pznfanadxqrvmp62gewy 21793430137afury  				
black add-genesis-account black17tc5dxkejps3adusaluzu7xn9jmg7qmwuem7gd 15016915068afury  				
black add-genesis-account black170k6xd7atru2uzmnqy345gyr5xcw8ke750tqpf 3754378082afury  				
black add-genesis-account black1xe7fkxfkl882uua6zyjadv296umtxdyk773ftg 6006646575afury  				
black add-genesis-account black1kxyzha73fnrzd8sf3a44dnl89whrvkdyum7s87 4505134247afury  				
black add-genesis-account black14z20ghpgxayvll6ppz9m4pxp939tx2uz6325w5 15016915068afury  				
black add-genesis-account black1pm350tzyg0rvvma7e43ezz729yxa5ljurrgs5c 138711309589afury  				
black add-genesis-account black1gwqvuzl4xwfwaxacygqkrux4dpgsl4duuw2ww7 17118673972afury  				
black add-genesis-account black1cuazcgw2m3x5r9gkyusrugn50wee4t9ps8e0ra 8301320548afury  				
black add-genesis-account black1rd4xs8xvggyrejjsemrjs9vxs4h6hdgql5zd9d 6006646575afury  				
black add-genesis-account black1klfd2u30qakx8qeqcw0xdcc3p3djq7ht727787 29692794520afury  				
black add-genesis-account black1xsmep764kqh3fq4rq7yp7t3qgnjycp9lf349ud 33997249314afury  				
black add-genesis-account black1tu4g3fpx9282y2ejt6zv6m9geq97mym5t07t8g 8109002740afury  				
black add-genesis-account black1ahrzs5snug646umdeeqrw6dap6ex0mntmzl5kp 4505134247afury  				
black add-genesis-account black1ymtq3eyk2s6q44phkqv8k35jqve52d0ztat3zv 15031249315afury  				
black add-genesis-account black10qrkeqjjdyx7zsfdx9cszj89xjph2ctmlvkcjh 7508158904afury  				
black add-genesis-account black1vvgh02zkh4qf9hydk0walw9nyx4udemrx5pp6g 18740832877afury  				
black add-genesis-account black1wa3lf2p624khztlrcz8kuh3sq8sfret26g0v4m 10511780822afury  				
black add-genesis-account black1hwapfpynu0evhdvhnge6929eu0hrpj5pwmhh0u 63798147946afury  				
black add-genesis-account black1u7wn3x6zphmuh0yuld7jly72725d4re6vkvzsk 105117808219afury  				
black add-genesis-account black1yrd99my556rvsfppfm96z6v7n439rr0x5feuwa 13515402740afury  				
black add-genesis-account black14lxhx09fyemu9lw46c9m9jk63cg6u8wdmclcmu 13830756164afury  				
black add-genesis-account black14c4ldwt8grnp6p9eq8kumw9uq63h8k462e628m 7508158904afury  				
black add-genesis-account black1hqgete6pcc2v6zsp6kl4dr892wwgdken3ezk9k 45050745205afury  				
black add-genesis-account black1pm3pva53gv4nnhvmduuh322pjmxv98t6lj3ayq 15027068493afury  				
black add-genesis-account black1zm3z7dd4ee8vfxu82lfmma4wmcnt3z8739xj4m 8304306849afury  				
black add-genesis-account black143yykhk2r0hpj572qw4f7669hnx64r8nylly9e 3754378082afury  				
black add-genesis-account black16wxtrzta2c9pnr3gxq7vax48kvhtw32ld4ymht 5255890411afury  				
black add-genesis-account black1pzt8ykkt4puf0xef4h0xgf4watffgp40pze542 7508158904afury  				
black add-genesis-account black1wltvdtjdnpe6uh5adg0m7ydy8cle8wwyre46mt 15029457534afury  				
black add-genesis-account black1le6qxteptv3cc29cyt2clm6zmzmn4x57yv758a 9010268493afury  				
black add-genesis-account black1d727nqk2j0k8pyd7qt9s4yh7x559r04a57lgwu 3754378082afury  				
black add-genesis-account black130s6vp9xk0h2fffcec0km06qp2nkdqjlcwzc0l 7508158904afury  				
black add-genesis-account black16uru2e0ja9j9fppg7at7s0pm0en5sr3r2t8s2p 30033830137afury  				
black add-genesis-account black1fh738d3juq6zysrgu5cg52kjqt4d2z3ggc9ah9 15184745205afury  				
black add-genesis-account black1fsezzt4rj6cm0my6z3f9hj3scvrkw5ns9fv6f6 4505134247afury  				
black add-genesis-account black12dlda2x3fm6rqyplnk2sdemspcc9gwdjwgzdmj 7508158904afury  				
black add-genesis-account black1w4v0tjfpfqrncl3mh8ezmceyjfjnnukzrd3tgt 11022438356afury  				



# Update total supply with claim values
#validators_supply=$(cat $HOME/.black/config/genesis.json | jq -r '.app_state["bank"]["supply"][0]["amount"]')
# Bc is required to add this big numbers
# total_supply=$(bc <<< "$amount_to_claim+$validators_supply")
# total_supply=1000000000000000000000000000
# cat $HOME/.black/config/genesis.json | jq -r --arg total_supply "$total_supply" '.app_state["bank"]["supply"][0]["amount"]=$total_supply' > $HOME/.black/config/tmp_genesis.json && mv $HOME/.black/config/tmp_genesis.json $HOME/.black/config/genesis.json

echo $KEYRING
echo $KEY
# Sign genesis transaction
black gentx $KEY2 100000000000000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID
#black gentx $KEY2 1000000000000000000000ablack --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
black collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
black validate-genesis

if [[ $1 == "pending" ]]; then
  echo "pending mode is on, please wait for the first block committed."
fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
# black start --pruning=nothing --trace --log_level info --minimum-gas-prices=0.0001ablack --json-rpc.api eth,txpool,personal,net,debug,web3 --rpc.laddr "tcp://0.0.0.0:26657" --api.enable true

