# rubocop:disable Metrics/ModuleLength
module Constants::AttorneyJudgeTeams
  # rubocop:disable Metrics/LineLength
  JUDGES = {
    preprod: {
      "BVAJWAGNER" => { attorneys: %w[CASEFLOW_283 CASEFLOW_317] },
      "CASEFLOW1" => { attorneys: %w[CASEFLOW_317 CASEFLOW_283 CF_KHAN_397] },
      "BVACPARKER" => { attorneys: %w[CASEFLOW_317 CF_KHAN_397] }
    },
    uat: {
      "CASEFLOW_317" => { attorneys: ["CF_DATA_317"] },
      "CF_PICARD_317" => { attorneys: %w[CF_SPOCK_317 CF_KHAN_397] },
      "CF_KIRK_397" => { attorneys: %w[CASEFLOW_283 CF_Q_317 CF_SCOTTY_397] }
    },
    test: {
      "BVARZIEMANN1" => { attorneys: %w[BVACFRANECKI1 BVAEDUBUQUE BVAKSIMONIS] },
      "BVABDANIEL" => { attorneys: %w[BVAAMACGYVER2 BVAMZEMLAK BVAEKOEPP] },
      "BVAFWINTHEIS" => { attorneys: %w[BVAKFEEST2 BVAKTRANTOW BVACUPTON1] }
    },
    development: {
      "BVARZIEMANN1" => { attorneys: %w[BVACFRANECKI1 BVAEDUBUQUE BVAKSIMONIS] },
      "BVABDANIEL" => { attorneys: %w[BVAAMACGYVER2 BVAMZEMLAK BVAEKOEPP] },
      "BVAFWINTHEIS" => { attorneys: %w[BVAKFEEST2 BVAKTRANTOW BVACUPTON1] },
      "BVAGBATZ" => { attorneys: %w[BVAUMCKENZIE BVATKUVALIS BVAJCONNELLY1] },
      "BVAMROOB" => { attorneys: %w[BVACBODE1 BVADKUHLMAN BVACPADBERG] },
      "BVAACUMMINGS" => { attorneys: %w[BVALHINTZ2 BVABHEATHCOT1 BVACSCHUPPE1] },
      "BVARKONOPELS" => { attorneys: %w[BVAKJACOBI BVAFKILBACK BVALERDMAN1] },
      "BVAMRITCHIE1" => { attorneys: %w[BVAFHYATT BVAETOY BVANJAKUBOWS] },
      "BVAJMUELLER1" => { attorneys: %w[BVAAHODKIEWI BVARSHANAHAN BVARBLANDA] },
      "BVADTERRY" => { attorneys: ["BVACWISOZK", "BVAMO'CONNEL", "BVACKOELPIN2"] },
      "BVAMABSHIRE" => { attorneys: %w[BVANGULGOWSK BVAHCORWIN1 BVAKBARTOLET] },
      "BVAHBOSCO" => { attorneys: %w[BVAABOGAN BVAAPAGAC BVACHALEY1] },
      "BVARERDMAN" => { attorneys: %w[BVASRITCHIE BVAJSCHIMMEL BVAKROHAN1] },
      "BVACTROMP" => { attorneys: %w[BVALJAST BVAJSCHMIDT3 BVALMILLS] },
      "BVAJHAND2" => { attorneys: %w[BVABWEST1 BVAEQUITZON BVAGHAMILL] },
      "BVAJHARBER1" => { attorneys: %w[BVATBATZ BVACGUTMANN BVALKOSS] },
      "BVAGJASKOLSK" => { attorneys: %w[BVAJCONNELLY BVAPSCHINNER1 BVAWLANG] },
      "BVAAMACGYVER1" => { attorneys: %w[BVADMORISSET BVAAPARISIAN BVAAERNSER] },
      "BVAKCONSIDIN1" => { attorneys: %w[BVADBRAKUS BVAHANDERSON BVAABERNIER] },
      "BVALBROWN1" => { attorneys: %w[BVADHAYES3 BVASLANG BVAEFEIL] },
      "BVASANKUNDIN" => { attorneys: %w[BVASROGAHN BVABROHAN1 BVAALEFFLER] },
      "BVASWARD" => { attorneys: %w[BVAFKOSS BVALKULAS BVAMPROSACCO] },
      "BVAGHILPERT1" => { attorneys: %w[BVAAEMMERICH BVARMARVIN BVALWISOZK1] },
      "BVATBARTOLET2" => { attorneys: %w[BVADREICHERT BVADSCHNEIDE BVAAWILL] },
      "BVACHAGENES1" => { attorneys: %w[BVAAMURAZIK3 BVAGRAYNOR BVAHMRAZ] },
      "BVABRAU" => { attorneys: %w[BVAWLARSON BVALMOSCISKI BVACDOOLEY] },
      "BVACONDRICKA" => { attorneys: %w[BVAATERRY1 BVAAGORCZANY1 BVAEUPTON] },
      "BVATLEGROS" => { attorneys: %w[BVAJWITTING BVADSCHUSTER BVACCARTER] },
      "BVAELEFFLER2" => { attorneys: %w[BVAFSCHOEN BVAEZEMLAK BVAHHOWE] },
      "BVABHOWE" => { attorneys: %w[BVAEBLANDA BVASTREMBLAY BVAFHELLER] },
      "BVAMDAVIS" => { attorneys: %w[BVAABARTELL BVADHALEY BVAKSTREICH] },
      "BVAECONNELLY" => { attorneys: %w[BVARCHRISTIA2 BVAAGORCZANY BVAMNIENOW] },
      "BVAAABSHIRE" => { attorneys: %w[BVAEERDMAN BVARDUBUQUE BVALSHIELDS] },
      "BVAAHARRIS2" => { attorneys: %w[BVATRYAN BVAJHOEGER BVAJKING] },
      "BVASANDERSON" => { attorneys: %w[BVALHARTMANN BVAEHODKIEWI BVALBERGSTRO] },
      "BVAHPAUCEK" => { attorneys: %w[BVAFBRUEN BVAFMANN BVAVSCHUPPE] },
      "BVABGISLASON" => { attorneys: %w[BVAWWEST BVACVOLKMAN BVAITORPHY] },
      "BVAIDUBUQUE1" => { attorneys: %w[BVAWSPENCER BVAWKUPHAL1 BVAMREYNOLDS] },
      "BVARGORCZANY1" => { attorneys: %w[BVAEDOYLE BVAJGISLASON BVAJHANSEN] },
      "BVAUHARVEY" => { attorneys: %w[BVAXCRUICKSH BVATBAHRINGE BVAKKOEPP] },
      "BVABMACEJKOV" => { attorneys: %w[BVAEBUCKRIDG BVAAHAMILL BVAETRANTOW] },
      "BVALSENGER" => { attorneys: %w[BVAJHEIDENRE BVAJBECKER BVABCASPER] },
      "BVALWALSH" => { attorneys: %w[BVAJDOUGLAS BVAHBATZ BVAFGIBSON] },
      "BVAVCASPER" => { attorneys: %w[BVAMERDMAN1 BVAMLEHNER1 BVAEORN] },
      "BVACBERGE1" => { attorneys: %w[BVAEBARTON1 BVABBLOCK BVACCRIST2] },
      "BVAILANGWORT" => { attorneys: %w[BVARPACOCHA BVACMACGYVER BVABTORPHY1] },
      "BVAGLEFFLER" => { attorneys: %w[BVAFPOLLICH BVASSCHUMM BVALMACEJKOV] },
      "BVAGSPORER" => { attorneys: %w[BVAOTRANTOW BVAGBOTSFORD BVAJWEHNER1] },
      "BVACKUHIC1" => { attorneys: %w[BVANSTANTON BVAMHARTMANN1 BVABCRONIN] },
      "BVAJRATH" => { attorneys: %w[BVAMKOELPIN BVASBRADTKE BVAEBECHTELA1] },
      "BVAQMARVIN" => { attorneys: %w[BVATWEIMANN BVAAZIEME1 BVAJHYATT2] },
      "BVALCASPER1" => { attorneys: %w[BVALALTENWER2 BVALQUITZON BVATCASSIN] },
      "BVAFWEBER" => { attorneys: %w[BVAMKRIS1 BVARLESCH BVANARMSTRON] },
      "BVASKREIGER" => { attorneys: %w[BVAMWILLIAMS1 BVACHEIDENRE BVAHHYATT] },
      "BVAGWEST" => { attorneys: %w[BVABFRANECKI BVAJKEMMER BVAETORP] },
      "BVAKBAUCH" => { attorneys: %w[BVAZLANG BVAMJENKINS BVADGAYLORD] },
      "BVATSHIELDS" => { attorneys: %w[BVADBOGISICH1 BVAEHOEGER1 BVAHDICKI] },
      "BVAJWHITE" => { attorneys: %w[BVAAKREIGER1 BVADBEAHAN BVATCARROLL1] },
      "BVAKDICKI" => { attorneys: %w[BVACDOUGLAS BVAJBREITENB BVAHBREITENB] },
      "BVAAFRITSCH1" => { attorneys: ["BVAJO'CONNEL", "BVAASPINKA", "BVALKERLUKE"] },
      "BVAAMOEN" => { attorneys: %w[BVAMEMMERICH1 BVAHGUSIKOWS1 BVAMMILLER] },
      "BVAMHAND" => { attorneys: %w[BVAAGRADY BVADWALKER BVANKOEPP] },
      "BVACHANSEN" => { attorneys: %w[BVALWIZA BVAMKRIS2 BVAJBARTOLET] },
      "BVAOJACOBI" => { attorneys: ["BVARTOWNE", "BVAKBAYER1", "BVAWO'KEEFE"] },
      "BVADBINS" => { attorneys: ["BVARO'HARA", "BVALMONAHAN", "BVARKOELPIN"] },
      "BVALWEST" => { attorneys: %w[BVASROBEL BVABROBEL BVACHAND] },
      "BVACPAGAC" => { attorneys: %w[BVAAPFEFFER BVAFDUBUQUE BVAEEMARD2] },
      "BVAMSMITH" => { attorneys: %w[BVAPJACOBI BVAGLESCH BVAAOLSON] },
      "BVAJO'CONNER" => { attorneys: %w[BVALBEATTY BVAAFISHER1 BVATRAU] },
      "BVATBREITENB" => { attorneys: %w[BVARSCHULIST BVALSTROMAN BVAPEFFERTZ] },
      "BVAKEBERT" => { attorneys: %w[BVAATHOMPSON BVALROWE BVAALABADIE] },
      "BVALANKUNDIN" => { attorneys: %w[BVALRUNOLFSD1 BVARBAUMBACH1 BVAMFEIL] },
      "BVAHTHOMPSON" => { attorneys: %w[BVAMGIBSON1 BVAAPACOCHA BVAADOOLEY] },
      "BVADJASKOLSK1" => { attorneys: %w[BVAASCHMIDT2 BVABLOWE BVAKBOEHM] },
      "BVAGHIRTHE" => { attorneys: %w[BVADMACEJKOV BVAZLEDNER BVAVBREKKE] },
      "BVASHUEL1" => { attorneys: %w[BVAAMACEJKOV1 BVAALARSON BVAJMCCULLOU] },
      "BVAGERNSER" => { attorneys: %w[BVABUPTON BVAAFRITSCH BVAESCHAMBER] },
      "BVAAHOMENICK" => { attorneys: %w[BVAABERGE BVAJBEATTY BVALRAYNOR] },
      "BVATREILLY" => { attorneys: ["BVABHOEGER", "BVAYTURCOTTE", "BVAKO'KEEFE"] },
      "BVASBAYER" => { attorneys: %w[BVAKWEST BVALLYNCH1 BVAMLOCKMAN] },
      "BVATLYNCH" => { attorneys: %w[BVALNIKOLAUS BVAFHILPERT BVAEMOEN] },
      "BVACTURCOTTE" => { attorneys: %w[BVACBINS BVAJVON BVAKHEANEY] },
      "BVAOVANDERVO" => { attorneys: %w[BVATMORAR BVALKEEBLER BVAAKONOPELS] },
      "BVAZROSENBAU" => { attorneys: %w[BVAADECKOW BVASWILKINSO BVACGULGOWSK] },
      "BVAEJACOBSON" => { attorneys: %w[BVAMROSENBAU BVAESPINKA BVAOREICHERT] },
      "BVAMSCHILLER" => { attorneys: %w[BVAJBATZ BVABGRAHAM1 BVACPARISIAN1] },
      "BVAEBLOCK1" => { attorneys: %w[BVAJHEATHCOT1 BVALLITTEL BVAYFERRY] },
      "BVASHOPPE" => { attorneys: %w[BVACMACEJKOV BVACPAUCEK BVAMPOUROS1] },
      "BVADCREMIN" => { attorneys: %w[BVAWBALISTRE BVACBOYLE BVAEAUER1] },
      "BVADSENGER" => { attorneys: %w[BVAJHANE1 BVAKKOVACEK BVAFGREENHOL] },
      "BVALHOWELL" => { attorneys: %w[BVATHEGMANN BVAMBARTON BVAPCRONA] },
      "BVAADONNELLY" => { attorneys: %w[BVARKUHLMAN BVAJDENESIK2 BVAAGERLACH] },
      "BVAMO'KON" => { attorneys: %w[BVAGLUETTGEN BVADSTOKES1 BVAMPACOCHA] },
      "BVATROMAGUER" => { attorneys: %w[BVAASTOKES BVAKMONAHAN BVACWILLIAMS] },
      "BVAQKOEPP" => { attorneys: %w[BVASRUTHERFO BVAAFEENEY1 BVAJHOEGER1] },
      "BVACLITTEL" => { attorneys: ["BVANOSINSKI", "BVAHBERGSTRO", "BVAEO'HARA1"] },
      "BVASHIRTHE" => { attorneys: %w[BVARVOLKMAN BVALROMAGUER1 BVANMILLER] },
      "BVALLITTLE" => { attorneys: %w[BVACCONSIDIN BVAMFARRELL BVAMHAMMES] },
      "BVAARUNOLFSD" => { attorneys: %w[BVATKEEBLER BVAMCASPER BVAJGRANT1] },
      "BVAHKREIGER" => { attorneys: %w[BVARRAU BVALLANGOSH1 BVARLEDNER1] },
      "BVACLAKIN" => { attorneys: %w[BVAHSCHILLER BVAKLEGROS BVAJSCHMIDT] },
      "BVAAO'HARA" => { attorneys: %w[BVAWWATSICA BVAETILLMAN1 BVAJBARTELL] },
      "BVASHUELS1" => { attorneys: %w[BVAJBAUCH1 BVAUDAUGHERT BVATKUPHAL1] },
      "BVAJCRUICKSH" => { attorneys: %w[BVAAKUNDE BVANSIPES1 BVALZBONCAK] },
      "BVAEBECKER" => { attorneys: %w[BVACREYNOLDS1 BVAMBOGISICH1 BVAKCORMIER] },
      "BVAAHAGENES" => { attorneys: %w[BVANRUTHERFO1 BVADTILLMAN BVATTHIEL] },
      "BVAJHOEGER2" => { attorneys: %w[BVABCRIST BVAHKLING BVACLYNCH3] },
      "BVAMWILDERMA" => { attorneys: %w[BVACKEELING1 BVAVDOOLEY BVAOZBONCAK] },
      "BVACCUMMERAT1" => { attorneys: %w[BVAKHINTZ BVAATORPHY1 BVAMALTENWER] },
      "BVAKKEELING" => { attorneys: %w[BVAROLSON BVAAYOST2 BVAMGRADY] },
      "BVANMANTE" => { attorneys: %w[BVAIROMAGUER BVACABSHIRE BVARFADEL] },
      "BVAAWITTING" => { attorneys: ["BVAFO'KON", "BVAMKRIS", "BVAJHARBER"] },
      "BVAMSCHNEIDE1" => { attorneys: %w[BVAWSCHULIST BVAWHEIDENRE BVAELEFFLER1] },
      "BVADFRAMI" => { attorneys: %w[BVADTILLMAN1 BVAASWIFT2 BVASSCHMITT] },
      "BVAABOGAN1" => { attorneys: %w[BVAANOLAN BVAAHILPERT BVADABBOTT] },
      "BVARCREMIN2" => { attorneys: %w[BVANKRIS1 BVATGOLDNER BVAEBARTOLET] },
      "BVAJBAILEY" => { attorneys: %w[BVAJMOORE BVAASIMONIS1 BVAELABADIE] },
      "BVALBARTON" => { attorneys: %w[BVAJDECKOW2 BVAKWEST1 BVAZMUELLER] },
      "BVAJREICHERT" => { attorneys: %w[BVAEKESSLER BVAJVON3 BVARKEMMER] },
      "BVALGUSIKOWS" => { attorneys: %w[BVAZHARRIS BVAVTRANTOW BVAPGIBSON] },
      "BVAAMCGLYNN" => { attorneys: %w[BVAAFARRELL1 BVAJHILLS BVALHODKIEWI] },
      "BVAGWILLIAMS" => { attorneys: %w[BVARSTREICH BVAMBATZ BVACSTRACKE] },
      "BVAMFRAMI" => { attorneys: %w[BVASKAUTZER BVAKBLICK BVACSIPES] },
      "BVAEFRAMI1" => { attorneys: %w[BVARREICHERT BVACCRIST BVAAMRAZ] },
      "BVAAJAST" => { attorneys: %w[BVATKRAJCIK BVASDECKOW BVAHLABADIE] },
      "BVAWBARROWS" => { attorneys: %w[BVAJMAGGIO BVASFISHER BVAKMOEN] },
      "BVAAROLFSON" => { attorneys: %w[BVAYBOEHM BVAMSMITH1 BVAMMCLAUGHL2] },
      "BVASWISOZK" => { attorneys: %w[BVAMROHAN BVAMSCHMELER1 BVAAFAY] },
      "BVAFFRITSCH" => { attorneys: %w[BVAJHEANEY1 BVALZIEMANN BVAMKASSULKE] },
      "BVALBERGNAUM" => { attorneys: %w[BVAHJERDE BVAEORTIZ BVAFORN1] },
      "BVAJBOGAN1" => { attorneys: %w[BVALJONES BVAAKOHLER BVAOGORCZANY] },
      "BVAKPROHASKA1" => { attorneys: %w[BVAKBRAUN BVABGREEN BVAGHERMAN] },
      "BVANKUVALIS" => { attorneys: %w[BVAPHERMAN BVAIBEER BVASSAUER] },
      "BVACKEELING" => { attorneys: %w[BVAHKIEHN BVACJOHNSTON BVACHAND1] },
      "BVAMGRANT" => { attorneys: %w[BVALVEUM BVAJSTREICH BVALHOWE] },
      "BVAOSCHOWALT" => { attorneys: %w[BVASCASPER1 BVAOWEHNER BVASFUNK1] },
      "BVALKUHLMAN" => { attorneys: %w[BVAGHAHN BVACROOB BVAPSCHINNER] },
      "BVAABATZ1" => { attorneys: %w[BVAJROWE BVAEYOST BVAJHAGENES] },
      "BVADMILLER" => { attorneys: %w[BVAKMURPHY BVAAOSINSKI BVALHAMMES1] },
      "BVACSCHMIDT1" => { attorneys: ["BVATMARVIN1", "BVAVLAKIN", "BVAOO'KEEFE"] },
      "BVAAKSHLERIN" => { attorneys: %w[BVADSCHMITT BVASDICKI2 BVAOSCHROEDE] },
      "BVAJCUMMERAT" => { attorneys: %w[BVAGHOMENICK BVACORTIZ BVAJGERLACH] },
      "BVAEGOODWIN" => { attorneys: %w[BVAGLARSON1 BVAVYOST BVADFRANECKI] },
      "BVAMWUCKERT" => { attorneys: ["BVATKLING", "BVABO'REILLY", "BVANSCHUSTER"] },
      "BVARPAUCEK" => { attorneys: %w[BVAJNIENOW BVASSHANAHAN BVAESCHNEIDE] },
      "BVAJHYATT" => { attorneys: %w[BVAJDICKI BVADHUDSON BVABCHAMPLIN] },
      "BVABUPTON1" => { attorneys: %w[BVAMWILLIAMS BVALTOY BVARLARSON] },
      "BVAPFRAMI" => { attorneys: %w[BVADHERMAN2 BVAKRAU BVADSPINKA] },
      "BVAWWHITE" => { attorneys: %w[BVAFPREDOVIC BVACCUMMERAT2 BVAECUMMERAT] },
      "BVAGO'HARA" => { attorneys: %w[BVAARIPPIN BVATTRANTOW BVAIWIZA] },
      "BVAEABSHIRE" => { attorneys: %w[BVACHARBER1 BVAHBAUMBACH BVAWSHANAHAN] },
      "BVAJSMITH" => { attorneys: %w[BVACABERNATH BVANHAAG BVADBOYER] },
      "BVANSCHULTZ1" => { attorneys: %w[BVAWRITCHIE1 BVARRYAN BVABREINGER] },
      "BVAJRAYNOR" => { attorneys: %w[BVAHDICKINSO BVALSATTERFI BVAJWIZA1] },
      "BVAKMORAR" => { attorneys: %w[BVAEHERMISTO BVABSTEHR BVAFROBEL] },
      "BVACFUNK" => { attorneys: %w[BVATPADBERG BVALTREUTEL BVAMSHIELDS1] },
      "BVAGKLING" => { attorneys: %w[BVAETHOMPSON BVADSHIELDS BVALREICHEL] },
      "BVADO'CONNER" => { attorneys: %w[BVAMERNSER1 BVAATREMBLAY BVALKOELPIN] },
      "BVAJCONSIDIN" => { attorneys: %w[BVADPACOCHA BVAMDAUGHERT1 BVAFTURCOTTE] },
      "BVAAMAYER" => { attorneys: %w[BVANHESSEL BVAHHOWELL BVASFISHER1] },
      "BVAMBEATTY1" => { attorneys: %w[BVACWARD BVAAGLEASON1 BVACKOSS1] },
      "BVAJBOEHM" => { attorneys: %w[BVALMCCLURE BVAAZIEME BVAGREICHERT] },
      "BVAIDUBUQUE" => { attorneys: %w[BVABDICKINSO BVAMHESSEL BVACBALISTRE] },
      "BVAMKING" => { attorneys: %w[BVAKSTAMM BVAGJOHNSON BVAKPOWLOWSK1] },
      "BVARJERDE" => { attorneys: %w[BVAMKIRLIN3 BVADWUNSCH BVARHACKETT] },
      "BVASRENNER" => { attorneys: %w[BVAMZBONCAK BVAMCHAMPLIN BVALREYNOLDS] },
      "BVAMTREMBLAY" => { attorneys: %w[BVAISATTERFI BVAMSCHNEIDE BVAAHAAG] },
      "BVAEEMARD" => { attorneys: %w[BVATGOYETTE BVAQZBONCAK BVACBARTON] },
      "BVAEHANE" => { attorneys: %w[BVACHARBER BVAAKULAS BVAVNOLAN] },
      "BVAMKUNDE1" => { attorneys: %w[BVACRAYNOR1 BVADRODRIGUE BVAKCOLLIER] },
      "BVARGLEASON" => { attorneys: ["BVAJO'HARA1", "BVAEWATERS", "BVAMBARROWS"] },
      "BVAJDENESIK" => { attorneys: %w[BVAVSCHNEIDE BVAEHAMILL1 BVABROHAN] },
      "BVAWSIMONIS" => { attorneys: %w[BVADFEEST BVADREINGER BVALQUITZON1] },
      "BVASBLANDA" => { attorneys: %w[BVALTORPHY BVAPWOLFF BVAFERDMAN] },
      "BVAMSTAMM" => { attorneys: %w[BVAMDICKENS BVAPHILLL BVAWOKUNEVA] },
      "BVASHARVEY" => { attorneys: %w[BVACSTOKES BVAGWOLF BVARWUNSCH] },
      "BVASHUDSON1" => { attorneys: %w[BVASWISOZK1 BVAAGISLASON BVACZIEME] },
      "BVAKDACH1" => { attorneys: %w[BVABRATH1 BVATCRUICKSH BVADKLEIN] },
      "BVACKOELPIN1" => { attorneys: ["BVARO'KON", "BVAATURNER", "BVAELUBOWITZ"] },
      "BVARCHRISTIA1" => { attorneys: %w[BVARHILPERT BVALFRITSCH BVAYALTENWER] },
      "BVACFRANECKI" => { attorneys: %w[BVAMERNSER2 BVAJWILDERMA BVAMLEANNON2] },
      "BVAAROBERTS1" => { attorneys: %w[BVADKUNDE BVAAZIEME2 BVADZIEMANN1] },
      "BVAMGERHOLD" => { attorneys: %w[BVAFHEANEY BVADMORAR BVAGWILDERMA] },
      "BVAACORKERY" => { attorneys: %w[BVAJKUHIC BVANJERDE BVAOWALSH] },
      "BVAAKERTZMAN" => { attorneys: %w[BVANMOEN BVAOGRADY1 BVACDAUGHERT] },
      "BVAVDARE" => { attorneys: %w[BVAJGRANT BVACGRAHAM BVAAWATSICA] },
      "BVAWJACOBI" => { attorneys: %w[BVACBEIER1 BVASKOZEY BVAETOWNE1] },
      "BVAYERNSER" => { attorneys: %w[BVADABERNATH BVARKUVALIS BVABWUNSCH] },
      "BVAJMARVIN" => { attorneys: %w[BVAEPADBERG BVAAPRICE BVAJRATKE] },
      "BVANEMMERICH" => { attorneys: %w[BVAJZIEME BVAHKSHLERIN BVANBERNHARD] },
      "BVAVMARKS" => { attorneys: %w[BVALBROWN BVAPRUECKER BVASSTRACKE1] },
      "BVAOFRANECKI" => { attorneys: %w[BVAKBLOCK BVACMERTZ BVAHLUETTGEN] },
      "BVAKPOWLOWSK" => { attorneys: %w[BVAJFISHER BVADSKILES BVAAHUELS1] },
      "BVANGLOVER" => { attorneys: %w[BVAETHOMPSON1 BVAJHETTINGE BVAJNITZSCHE] },
      "BVAADICKENS" => { attorneys: %w[BVAGFAHEY BVAAKUPHAL1 BVANPFANNERS] },
      "BVACMEDHURST" => { attorneys: %w[BVADKUHN1 BVAKMAYER BVAOFADEL] },
      "BVAKBOGAN" => { attorneys: %w[BVARORN BVASWUNSCH BVALHUELS] },
      "BVABZIEMANN" => { attorneys: %w[BVAKBEIER BVASSTRACKE BVAJJERDE1] },
      "BVAWHACKETT" => { attorneys: %w[BVAZOLSON BVADZIEMANN BVARWOLF1] },
      "BVACKASSULKE" => { attorneys: %w[BVAJMETZ BVAMGUSIKOWS1 BVARMAYER] },
      "BVAMJOHNSTON" => { attorneys: %w[BVAEMCDERMOT BVACKOEPP BVANHILLL] },
      "BVACHERMISTO" => { attorneys: %w[BVAOCARROLL BVATBROWN BVAAWELCH1] },
      "BVADHUELS" => { attorneys: %w[BVAAJENKINS1 BVADDOUGLAS BVARRODRIGUE] },
      "BVAGPAUCEK" => { attorneys: %w[BVALLARSON1 BVAADICKINSO BVAJMOSCISKI] },
      "BVATGREENHOL" => { attorneys: %w[BVABRATKE BVAAHOWELL BVAAZEMLAK2] },
      "BVAABODE" => { attorneys: %w[BVAVFRAMI BVAMSKILES1 BVARREYNOLDS] },
      "BVADPFEFFER" => { attorneys: %w[BVAMDAVIS1 BVAASHIELDS BVAVWIZA] },
      "BVABWOLFF" => { attorneys: %w[BVACSIMONIS1 BVAAJASKOLSK BVAAMARVIN1] },
      "BVABANKUNDIN" => { attorneys: %w[BVAGWUCKERT BVACMCLAUGHL1 BVAWHAUCK] },
      "BVAZCREMIN" => { attorneys: %w[BVAVBEER BVAKMULLER BVALFAY] },
      "BVAHPRICE" => { attorneys: %w[BVAJRUNTE BVAGPOWLOWSK1 BVAMMORISSET] },
      "BVAWEBERT" => { attorneys: %w[BVAMKUNDE BVACLEMKE1 BVADHINTZ] },
      "BVAFKING" => { attorneys: %w[BVAMSTROMAN BVABFRITSCH BVAAKIHN] },
      "BVAFBEAHAN" => { attorneys: %w[BVAGHYATT BVASHINTZ] }
    },
    prod: {
      "BVADAMES" => { attorneys: %w[BVATBLAKE VACOBRUNOR VACOFOWLEJ BVARFRANK BVAJLYONS VACORIORDB BVAAROCK VACOSTEVEN] },
      "VACOCARACA" => { attorneys: %w[VACOCRAWFL VACODEEMEG VACOGANDHR VACOJOSEPT BVAJTRICKEY VACOWALKEW BVAGFENICE BVATMINOT] },
      "BVAKHADDOCK" => { attorneys: %w[VACOQUANTC BVAICANNADAY BVASKRUNIC BVASMISHA VACOODONNC VACOSAMIA BVAASHAWKEY VACOSIMM VACOWARED] },
      "BVAMDLYON" => { attorneys: %w[VACOFRANKP VACOHARRIM30 BVAMMILLER BVACMURRAY BVASSIESSER VACOTAYLOY] },
      "BVAAMAINELLI" => { attorneys: %w[BVAHJHARTER BVACHOWELL VACONARDUV VACOOCONNM BVACORIE VACORASOON VACOREIDJ BVATWILLIE] },
      "VACOSTROMG" => { attorneys: %w[BVAJADAVIS BVAHBROKOWSKY VACOGROSSC VACOLAFFIK VACOSAHRAZ BVAMSCHLICK VACOSMITHA5 BVAKSPRAGINS] },
      "VACOWHITEY" => { attorneys: %w[VACOABDELD BVAABARNER BVATSYKES VACOCHOC BVAALECH VACOLILLYG VACOZHURAM BVAMMOORE BVAPOLSON] },
      "BVADWIGHT" => { attorneys: %w[VACOBLAKER VACOMILLEE VACONELSOJ BVAMNYE VACORAJS BVAPRUBIN VACOTIMBEM BVARWATKINS] },
      "BVAJWILLS" => { attorneys: %w[VACOCHILCD1 VACOKUCZYR BVAKOSEGUEDA BVAMPOSTEK BVABRIDEOUT BVAJSAIKH VACOWALKEK3 BVAMWULFF] },
      "BVAPMLYNCH" => { attorneys: %w[BVAJRUTKIN BVALMCCABE BVANSANGSTER BVAMPURDUM VACOSTEDMM VACODENTOB VACOSINCKL VACOMUSSES2 VACOEDWARC] },
      "BVASKENNEDY" => { attorneys: %w[BVAJCONOLLY BVACWASSER BVASBARIAL BVASSPICKNALL BVAMCOYNE VACOCOSTEJ1 VACOBATTER VACOFLOORN VACOFLEURG] },
      "BVANDOAN" => { attorneys: %w[BVAADEAN BVADDONAHUE BVAAHEMPHILL VACOSOLOMS VACODERMAM VACOTHOMPK3 VACOMOOREY BVAAGIBSON VACOKASSC] },
      "BVADBROWN" => { attorneys: %w[VACOFERRAC BVAMCARSTEN BVAHABEACH BVAMRUDE VACOMONTAJ VACOBAMETP VACOBOOKET VACOKERPAA] },
      "BVAHROBERT" => { attorneys: %w[VACOMONDEE BVAJTHUTCHS BVASLAYTON BVATGILLETT BVAZZHU BVALNOTTLE VACOCROSSK VACOAHMADH VACOCOXT2 VACOFLYNNG] },
      "BVAMTENNER" => { attorneys: %w[VACOVASSAM BVASPATEL BVAJESSMITH BVATYHAWKINS BVAEANDERSON VACOMACEKM VACOWHITEB4 VACOPENDLN VACOPRATTV BVAADJAKSON] },
      "BVAJHWA" => { attorneys: %w[VACOMUZZAR VACONEGROJ VACOFORDC BVAKPARKE VACOFREEMJ2 BVACCYKOWSKI VACOBUSHL2 VACOCASEYC] },
      "BVALREIN" => { attorneys: %w[VACOMAHAFC VACOPITTSA VACOPARRIA BVAJSHAW VACOBARBEM2 VACOCOOGAJ VACODELLAA BVASFINN BVACRYAN VACOKOE] },
      "BVAMHAWLEY" => { attorneys: %w[VACOHODGEB VACOKELLYD BVAMRILEY BVATGRIFFIN BVAGSLOVICK BVABWILLIAMS BVAWRIPP VACOMORRISJ VACOFERGUS1 VACONORWOA] },
      "BVAAMACKEN" => { attorneys: %w[VACOHICKSE BVAMYOUNG BVALBARSTOW BVAALEVANS BVAJABRAMS BVACCOLLINS VACOQUARLB VACOMUKHEC VACOBANKSC4] },
      "BVAGRSENYK" => { attorneys: %w[VACOCORDIE BVAJRSIEGEL BVADBREITBEIL BVADSCHECH VACOSKOWRW BVAJDUPONT VACOBAYLESJJ VACOSTASKN VACOPOINDP] },
      "BVAVMOSHI" => { attorneys: %w[VACOMCKONK VACOARRITD VACOKUCERC BVAMYUAN BVATMATTA VACOSHOWAM VACOROBINN VACODAILLM VACOLAMBES] },
      "BVAMCGRAHAM" => { attorneys: %w[BVACLAWSON BVAKHUGHES BVASKREITLOW BVAABARONE BVATWISHARD VACOHERDLB2 VACOFALEST VACOANDERC12] },
      "BVAMELARKIN" => { attorneys: %w[VACOMARRAK BVAJRDAVIT BVARBURRIESCI BVARPATNER BVAJKOMPERDA BVACBIGGINS BVAESTRUENING VACOPERKIM5 VACOMCLEOP] },
      "BVAMSORISIO" => { attorneys: %w[VACOPAKK VACOWHITEM5 BVALWGREEN BVABYOON BVALYANTZ BVAKWALTERS VACOSTALLL VACOPATELS VACOBREITN VACODEANR2] },
      "BVAEVPAREDEZ" => { attorneys: %w[BVAKWALLIN BVAJMEAWAD VACOFOSTEK5 VACOMOOREB1 VACOSANDLJ VACOHARRIR3 VACOARNOLA2 VACOROEA] },
      "BVATKONYA" => { attorneys: %w[BVASPFLUGNER BVANMCELWAIN BVAAHAMPTON BVAGFRASER VACOFERGUA VACONELSOL3 VACOWINBUB VACOMARTIC9] },
      "BVAURPOWELL" => { attorneys: %w[VACOLEARYS BVAABUDD BVAAFLAMINI BVAJHENRIQUEZ BVAMESPINOZA VACOBAKERJH VACOLEMOIB] },
      "BVAMMARTIN" => { attorneys: %w[VACOSMITHK BVAJDEANE BVAMPKATZ BVATANTHONY BVAJOCONNELL BVAASOLOMON VACOMOUNTS VACOBROWNS VACOHIGGIJ] },
      "BVALJENG" => { attorneys: %w[BVAAALDERMAN BVAMJIN BVADSCHECHT VACORAFTEG VACOBROWNN6 VACOINNETL VACOFREEMS BVANKAMAL] },
      "BVABMULLINS" => { attorneys: %w[BVASCHINNERER BVAPVERESINK BVAANOLLEY VACOKUTROA VACOLEEY1 VACOFISHEH VACOWHITAN VACOTROTTR VACOKINGT10] },
      "BVALHOWELL" => { attorneys: %w[VACORAGOFD VACOHAMILD1 VACOKOKOLT BVAEREDMAN BVAKSCHAEFER BVAKKOVAROVIC VACOYACOUM VACOSPIGEA VACOBERNAT VACOEVANSB] },
      "BVAKBANFIELD" => { attorneys: %w[VACOWILSOG BVAJJENKINS BVADCAMILLERI BVAWMYATES BVACBANISTER VACOMEDINS VACOMAMISR VACOBIRDEM] },
      "BVANKROES" => { attorneys: %w[VACOSHUSTM BVACBOYD BVADHAVELKA BVARVELDENZ BVAEBRANDAU BVAMBRUCE BVAAWEIS VACOGONZAM6 VACOSCARDR] },
      "BVAVCLEMENT" => { attorneys: %w[VACOMCLENS VACOEMMART VACOANWARS2 VACOCOHENB VACOCOLLEC BVAGJACKSON BVAJMILLER VACOMILLEN2 VACOWOZNIJ] },
      "BVAMLKANE" => { attorneys: %w[VACOREYNOP VACOHOYG BVALMOLLAN VACOGALANM BVAKHUBERS VACOJANOFR BVAMLAVAN VACOLEAMOJ VACOPARSOA] },
      "BVAJBKRAMER" => { attorneys: %w[VACOBERNAT1 BVALMCRAMP VACODUTHEE BVAJGALLAGHER BVAAMACK BVAJRAGHEB VACORAYMOS VACOSCHNIM BVATSHERR] },
      "BVASBELCHER" => { attorneys: %w[BVARCASADEI VACOFARREB2 VACOHARPET BVAJLEE VACOLOGANL1 BVAJNICHOLS BVAMTHOMAS VACOYAFFEA] },
      "BVAKPARAKAL" => { attorneys: %w[VACODAVISM2 VACOCARMAF BVAPJOHNS BVATSKELLY BVACKUNG BVAKKUNZ VACOOWENSS BVARFWILLIAMS VACOWOODAM] },
      "BVAJPARKER" => { attorneys: %w[VACODYER VACOBEDFOA BVAEBLOWERS BVAPKINGERY VACOCHOIE1 BVACPALMER VACOMEEHAP VACOMOORES BVAATENNEY] },
      "BVAHSEESEL" => { attorneys: %w[VACOIANNOE VACOBOALA BVAACHRIST BVARCONNALLY BVATHJONES VACOJONESE20 BVANNELSON VACOTEAGUC3] },
      "BVAAPSIMPSON" => { attorneys: %w[VACOVASILS VACOKAPELA VACOCHENGD BVAAHODZIC VACOHUSAIR BVADCJOHNSON VACOKENINA VACOROSENE VACOSTALLIJ BVALYASUI] },
      "BVAAJAEGER" => { attorneys: %w[VACOALSTOT VACOGAYEE VACOBROOKB4 BVAMOLSON VACOCLARKK1 VACOESTESJ VACOHTUNL BVAAPANIO BVAKSOSNA VACOSTANTK] },
      "BVADJOHNSON" => { attorneys: %w[VACOBARRED BVADBASSETT BVAMGMAZUCH BVAMSOBIECKI VACOTANGM BVAAVIEUX VACOVUONGK VACOMORTIE] },
      "BVAJCROWLEY" => { attorneys: %w[VACOVANVAE VACOCAMPB7 BVAATATIANA VACOKETTLR BVAMMARCUM VACOSNOPAA BVASSORATHIA BVANWERNER VACOWOEHLV] },
      "BVAMJSKALT" => { attorneys: %w[VACOKINGJ VACOMONTAA VACOCANNOB BVASDALE VACODANIEA2 VACODAUGHP VACOGARCIAJ VACORESCAM BVASSHOREMAN] },
      "BVARKESSEL" => { attorneys: %w[VACOPAGANW VACOMORFOS BVACBOSELY BVAPCHILDERS VACOGEORGEJ BVABISAACS VACOJIMERD BVAASANTIAGO BVAMTAYLOR VACOGRAYE VACOMORFOS VACOPAGANW] },
      "BVASKREMBS" => { attorneys: %w[VACOTEMPLB VACOSNYDEM VACOALTENI VACOBILSTM BVAAFAGAN VACOPETTIN VACOSMITHJ5 BVALSTEPANICK VACOTIMMEP] },
      "BVASBUSH" => { attorneys: %w[VACOROUSEG VACOASANTR BVAJLIVEY VACOMAHONS BVAJMARLEY BVANNORTHCUTT BVAKQUANDER] },
      "BVASDREISS" => { attorneys: %wVACOJONEST1 BVAJCASTILLO VACOCIARDK VACOJORDANJ BVAJKITLAS BVASREGAN BVACSAMUELSON BVATWESNER BVAMAWILSON VACOWYSOKK] },
      "BVAMBLACK" => { attorneys: %w[BVATBERRYMAN VACODAVIDC BVASECKERMA VACOFRANKM2 VACOSIMSR VACOYEHN] },
      "BVABBCOPELD" => { attorneys: %w[VACOCRAWFJ2 BVAJDWORKIN BVADSEATON BVATHSMITH VACOWAINAS] },
      "BVACFLEMING" => { attorneys: %w[VACOSTUEDA BVAAMCLARK VACOCOMNIG BVALCONNOR VACOJIGGET VACOKATZD3 VACONEALM VACOTHOMPM6] },
      "BVASHENEKS" => { attorneys: %w[VACOONYEOO BVADBREDEHORS BVADBROOK BVANKAMAL VACOKUNJUE BVACLAMB VACONOHP VACOWIMBIA] },
      "BVAMHERMAN" => { attorneys: %w[VACOALHINM BVAJBURRO BVATDOUGLAS VACOGRZECT VACOHUMPHD VACOLEEM2 BVAMMAC VACOREKOWE VACOSAINDP] },
      "BVAAISHIZ" => { attorneys: %w[VACOALEXAJ10 BVADMCASULA BVAKCHURCH BVAKFLETCHER BVAJPGERVAS VACOJOHNSS3 VACOMETZNP VACOSHAHN1 VACOVEMULR] },
      "BVAKKORDICH" => { attorneys: %w[BVATSADAMS VACOANS BVAACRYAN VACOHOULED BVAJKIM VACOMOORET10 BVAMSOPKO VACOWINKLT BVAFFULLER] },
      "BVAKMILLIKAN" => { attorneys: %w[VACOMARTIS5 VACOBRUTOC BVASGINSKI BVADSNELSON VACONGUYEP BVACSMITH BVAHYOO] },
      "BVATOSHAY" => { attorneys: %w[VACOBARDIA BVASFLOT BVAJRBRYANT BVAJCHENG BVAJFLYNN VACOKALOLS BVACLKRAS BVAKMITCHELL VACOPEDENN VACOHITED BVACKAMMEL] },
      "BVADWSINGLE" => { attorneys: %w[VACOMIDDLS2 BVAJFUSSELL BVAHHOEFT BVARKIPPER VACOLEWISB VACOMORRAS VACOHANSOT VACOHOOVEL VACOLINM] },
      "BVAHWALKER" => { attorneys: %w[VACOJACKJ VACOMMEJEN BVAALINDIO BVAKGIELOW BVAMMCPHAULL BVAMLUBOCH BVAESKIOURIS VACOPRICEA VACOTALAMT VACODECHIA] },
      "BVALBARNARD" => { attorneys: %w[VACOHARTFM BVAJMOATS BVAAMADDOX BVAAZENZANO BVAJUNGER VACOSUHG VACOLEEJ5 VACOZIMMEM VACOWHITLJ] },
      "BVAMAUER" => { attorneys: %w[VACOMIDDLJ BVAAAHLBERG BVASBOEHM BVASKIM BVAAPURCELL VACOGASTOK VACODAVIST1 VACOSHANNT] },
      "BVAMKILCOYN" => { attorneys: %w[VACOJAIGIB BVAAADAMSON BVARDODD BVACBATES BVAPHOGAN VACOCARROE VACOJENSER VACOELLIOR VACOULLERJ] },
      "BVARFEINBERG" => { attorneys: %w[VACOFOURNS BVAMOSBORNE BVAATURNIP BVAJOLSEN BVAJWILLIAMS VACODAUSH VACOWARREI VACOHITCHI] },
      "BVATASMITH" => { attorneys: %w[VACOROBERJ6 BVALEDWARDS BVAMHANNAN BVAEJALLEY VACOJAMISE VACOTAYLOC VACOPALACA VACORUIZR] },
      "BVAVCHIAPP" => { attorneys: %w[VACOSEBSTD VACODUPRED BVALCROHE BVADEBAUGH BVAJSPRINGER VACOJOHNSP2 VACOWILLIL12 VACOGIAQUM VACOBROZYK] },
      "BVAHSCHARTZ" => { attorneys: %w[BVANRIPPEL BVAASYED BVAMSUFFOLE BVARSTEPHENS VACOYOFFEP VACOSHANNG VACOCREEGA] },
      "BVAJFRANCIS" => { attorneys: %w[VACODICKET BVACHOUBECK BVAJSCHROADER BVASHOOPEN BVAKKARDIAN VACOFITZGT VACOONGG VACOHARNEC1] },
      "BVADHACHEY" => { attorneys: %w[VACOZHENGA BVACASKOW VACOLJBAKKE BVADLEE BVASDELHAUER VACOMINEE VACOSCHICS VACOBRANDK1 VACOSALAZM] },
      "BVAMLANE" => { attorneys: %w[VACOHEBERM VACOKIMJ5 BVAJTAYLOR BVADTCHERRY BVAJDEFRANK BVAAVANVALK VACODUFFYM VACOHENRYT VACOMORRAS1 VACOKEOGHN] },
      "BVAKALIBRAN" => { attorneys: %w[VACOLUBYM VACOSTEELE BVAJMURRAY BVAJKESELYAK BVASREED VACOVANGS VACOBAXTES VACOMARSHA VACOMCDONK4] },
      "BVAMAPAPPAS" => { attorneys: %w[VACOMULRAG BVALBCRYAN BVAAMICHEL VACOBASKEL BVAJTUNIS VACOBODIB VACOSETTEJ VACOKEELEB VACOWATSOM3] },
      "BVAKGUNN" => { attorneys: %w[VACOKHANS VACOSLAUGA BVAJBARONE BVAMDORAN BVATSAMAD BVAKGEORGIEV VACOSILVERL VACOKOMINB VACOUMOI VACOMCDUFK] },
      "BVAGWASIK" => { attorneys: %w[VACORONQUE BVAREPJONES BVACMCENTEE BVASNAJARIAN BVAMLUNGER VACOTISSEJ VACOPRINSS VACOWADEJ] },
      "BVAESLEBOFF" => { attorneys: %w[VACOGLENNR VACOSHELTA BVACECKART BVACHANDY BVAMKREINDLER BVAMPREM BVAWSNYDER VACOHURLES VACOGRIFFJ] },
      "BVAPSORISIO" => { attorneys: %w[VACOMACCHP VACOHAND BVAJPRICHRD BVAPLOPEZ VACOSHOUMM VACOWILLIA5 VACOCRUZK VACOGELBEJ VACOMORALG] },
      "BVAJHAGER" => { attorneys: %w[BVACDALE BVABELWOOD BVAACASTILLO BVALLEIFERT VACOMADDOR1 VACOLAROCN VACOCUMMIJ] },
      "BVAJMONROE" => { attorneys: %w[VACOWELLSW1 BVAKNEILSON BVAMSANFORD BVAMWILSON BVASCAMPBELL BVAJROTH VACORASULH VACOGANNOC] },
      "BVAJREINHART" => { attorneys: %w[VACOLEUNGD BVAMPETERS BVASSTVIL BVASKEYVAN BVABCLEARY BVACSPEARS BVAABAKER VACOLABIA VACOPATRICN] },
      "BVAMHYLAND" => { attorneys: %w[BVAMHARRIGAN BVABBERRY BVALKYLE BVASGORDON VACOJOSEYK VACOREEDB1 VACOCELTNJ VACOPITMAD] },
      "BVABKNOPE" => { attorneys: %w[VACOPAGEA BVAABORDEWYK BVADORFANO BVAMPRYCE VACOMEYERJ2 VACOBORMAA VACOMASKAZ VACOVAMPLE VACOCROSNM] },
      "BVAKBCONNER" => { attorneys: %w[VACOKUKSOK VACOSEEHUS VACOBEHLER BVAKBUCKLEY VACOFAVERA BVACHERJONES VACOKLEPOK BVALKSTRAUSS VACOWALKER VACOYUNH BVAKCHANCE] }
    }
  }.freeze
  # rubocop:enable Metrics/LineLength
end
# rubocop:enable Metrics/ModuleLength
