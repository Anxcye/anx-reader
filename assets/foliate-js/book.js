// //////// use for test //////////
// const importing = false
// const allAnnotations = [
//   // { id: 1, type: 'highlight', value: "epubcfi(/6/6!/4/2,/1:3,/1:4)", color: 'blue', note: 'this is' },
//   // { id: 2, type: 'highlight', value: "epubcfi(/6/6!/4/576,/1:2,/1:3)", color: 'yellow', note: 'this is' },
//   // { id: 3, type: 'underline', value: "epubcfi(/6/4!/4/4,/1:294,/1:301)", color: 'red', note: 'this is' },
// ]
// let url = '../local/shj.epub'
// let initialCfi = "epubcfi(/6/12!/4,/2[CHP3],/8/1:29)"
// //  let initialCfi = null
// let style = {
//   fontSize: 1.2,
//   fontName: 'book',
//   letterSpacing: 0,
//   spacing: 1.7,
//   paragraphSpacing: 1,
//   textIndent: 5,
//   fontColor: '#0000ff',
//   backgroundColor: '#ffffff',
//   topMargin: 100,
//   bottomMargin: 100,
//   sideMargin: 5,
//   justify: true,
//   hyphenate: true,
//   // scroll: false,
//   // animated: true,
//   pageTurnStyle: 'slide'
// }
// window.flutter_inappwebview = {}
// window.flutter_inappwebview.callHandler = (name, data) => {
//   console.log(name, data)
// }
// setTimeout(() => {
//   reader.renderAnnotation()
// }, 1000)

// // 'none', 's2t', 't2s'
// let convertChineseMode = 'none'

// ///////////////////////////////

console.log('book.js')

import './view.js'
import { FootnoteHandler } from './footnotes.js'
import { Overlayer } from './overlayer.js'
const { configure, ZipReader, BlobReader, TextWriter, BlobWriter } =
  await import('./vendor/zip.js')
const { EPUB } = await import('./epub.js')

// https://github.com/johnfactotum/foliate
const debounce = (f, wait, immediate) => {
  let timeout
  return (...args) => {
    const later = () => {
      timeout = null
      if (!immediate) f(...args)
    }
    const callNow = immediate && !timeout
    if (timeout) clearTimeout(timeout)
    timeout = setTimeout(later, wait)
    if (callNow) f(...args)
  }
}

const pointIsInView = ({ x, y }) =>
  x > 0 && y > 0 && x < window.innerWidth && y < window.innerHeight;

const frameRect = (frame, rect, sx = 1, sy = 1) => {
  const left = sx * rect.left + frame.left;
  const right = sx * rect.right + frame.left;
  const top = sy * rect.top + frame.top;
  const bottom = sy * rect.bottom + frame.top;
  return { left, right, top, bottom };
};

const getLang = el => {
  const lang = el.lang || el?.getAttributeNS?.('http://www.w3.org/XML/1998/namespace', 'lang');
  if (lang) return lang;
  if (el.parentElement) return getLang(el.parentElement);
};

const getPosition = target => {
  const frameElement = (target.getRootNode?.() ?? target?.endContainer?.getRootNode?.())
    ?.defaultView?.frameElement;

  const transform = frameElement ? getComputedStyle(frameElement).transform : '';
  const match = transform.match(/matrix\((.+)\)/);
  const [sx, , , sy] = match?.[1]?.split(/\s*,\s*/)?.map(x => parseFloat(x)) ?? [];

  const frame = frameElement?.getBoundingClientRect() ?? { top: 0, left: 0 };
  const rects = Array.from(target.getClientRects());
  const first = frameRect(frame, rects[0], sx, sy);
  const last = frameRect(frame, rects.at(-1), sx, sy);
  const screenWidth = window.innerWidth;
  const screenHeight = window.innerHeight;
  const start = {
    point: { x: ((first.left + first.right) / 2) / screenWidth, y: first.top / screenHeight },
    dir: 'up',
  };
  const end = {
    point: { x: ((last.left + last.right) / 2) / screenWidth, y: last.bottom / screenHeight },
    dir: 'down',
  };
  const startInView = pointIsInView(start.point);
  const endInView = pointIsInView(end.point);
  if (!startInView && !endInView) return { point: { x: 0, y: 0 } };
  if (!startInView) return end;
  if (!endInView) return start;
  return start.point.y * screenHeight > window.innerHeight - end.point.y * screenHeight ? start : end;
};

const getSelectionRange = sel => {
  if (!sel || !sel.rangeCount) return;
  const range = sel?.getRangeAt(0);
  if (range.collapsed) return;
  return range;
};

//    let isSelecting = false;

const handleSelection = (view, doc, index) => {
  //    isSelecting = false;
  const sel = doc.getSelection();
  const range = getSelectionRange(sel);
  if (!range) return;
  const pos = getPosition(range);
  const cfi = view.getCFI(index, range);
  const lang = getLang(range.commonAncestorContainer);
  const text = sel.toString();
  if (!text) {
    const newSel = range.startContainer.ownerDocument.getSelection()
    newSel.removeAllRanges()
    newSel.addRange(range)
    text = newSel.toString()
  }
  // onSelectionEnd({ index, range, lang, cfi, pos, text });
  // return 
  onSelectionEnd({ index, range, lang, cfi, pos, text })
}

const setSelectionHandler = (view, doc, index) => {
  //    doc.addEventListener('pointerdown', () => isSelecting = true);
  // if windows
  if (navigator.platform.includes('Win')) {
    doc.addEventListener('pointerup', () => handleSelection(view, doc, index));
  }
  // doc.addEventListener('selectionchange', () => handleSelection(view, doc, index));

  if (!view.isFixedLayout)
    // go to the next page when selecting to the end of a page
    // this makes it possible to select across pages
    doc.addEventListener('selectionchange', debounce(() => {
      //            if (!isSelecting) return
      if (view.renderer.getAttribute('flow') !== 'paginated') return
      const { lastLocation } = view
      if (!lastLocation) return
      const selRange = getSelectionRange(doc.getSelection())
      if (!selRange) return
      if (selRange.compareBoundaryPoints(Range.END_TO_END, lastLocation.range) >= 0) {
        view.next()
      }
    }, 1000))

};

const isZip = async file => {
  const arr = new Uint8Array(await file.slice(0, 4).arrayBuffer())
  return arr[0] === 0x50 && arr[1] === 0x4b && arr[2] === 0x03 && arr[3] === 0x04
}

const isPDF = async file => {
  const arr = new Uint8Array(await file.slice(0, 5).arrayBuffer())
  return arr[0] === 0x25
    && arr[1] === 0x50 && arr[2] === 0x44 && arr[3] === 0x46
    && arr[4] === 0x2d
}

const makeZipLoader = async file => {
  configure({ useWebWorkers: false })
  const reader = new ZipReader(new BlobReader(file))
  const entries = await reader.getEntries()
  const map = new Map(entries.map(entry => [entry.filename, entry]))
  const load = f => (name, ...args) =>
    map.has(name) ? f(map.get(name), ...args) : null
  const loadText = load(entry => entry.getData(new TextWriter()))
  const loadBlob = load((entry, type) => entry.getData(new BlobWriter(type)))
  const getSize = name => map.get(name)?.uncompressedSize ?? 0
  return { entries, loadText, loadBlob, getSize }
}

const getFileEntries = async entry => entry.isFile ? entry
  : (await Promise.all(Array.from(
    await new Promise((resolve, reject) => entry.createReader()
      .readEntries(entries => resolve(entries), error => reject(error))),
    getFileEntries))).flat()

const makeDirectoryLoader = async entry => {
  const entries = await getFileEntries(entry)
  const files = await Promise.all(
    entries.map(entry => new Promise((resolve, reject) =>
      entry.file(file => resolve([file, entry.fullPath]),
        error => reject(error)))))
  const map = new Map(files.map(([file, path]) =>
    [path.replace(entry.fullPath + '/', ''), file]))
  const decoder = new TextDecoder()
  const decode = x => x ? decoder.decode(x) : null
  const getBuffer = name => map.get(name)?.arrayBuffer() ?? null
  const loadText = async name => decode(await getBuffer(name))
  const loadBlob = name => map.get(name)
  const getSize = name => map.get(name)?.size ?? 0
  return { loadText, loadBlob, getSize }
}

const isCBZ = ({ name, type }) =>
  type === 'application/vnd.comicbook+zip' || name.endsWith('.cbz')

const isFB2 = ({ name, type }) =>
  type === 'application/x-fictionbook+xml' || name.endsWith('.fb2')

const isFBZ = ({ name, type }) =>
  type === 'application/x-zip-compressed-fb2'
  || name.endsWith('.fb2.zip') || name.endsWith('.fbz')

const getView = async file => {
  let book
  if (file.isDirectory) {
    const loader = await makeDirectoryLoader(file)
    const { EPUB } = await import('./epub.js')
    book = await new EPUB(loader).init()
  }
  else if (!file.size) throw new Error('File not found')
  else if (await isZip(file)) {
    const loader = await makeZipLoader(file)
    if (isCBZ(file)) {
      const { makeComicBook } = await import('./comic-book.js')
      book = makeComicBook(loader, file)
    } else if (isFBZ(file)) {
      const { makeFB2 } = await import('./fb2.js')
      const { entries } = loader
      const entry = entries.find(entry => entry.filename.endsWith('.fb2'))
      const blob = await loader.loadBlob((entry ?? entries[0]).filename)
      book = await makeFB2(blob)
    } else {
      book = await new EPUB(loader).init()
    }
  }
  else if (await isPDF(file)) {
    const { makePDF } = await import('./pdf.js')
    book = await makePDF(file)
  }
  else {
    const { isMOBI, MOBI } = await import('./mobi.js')
    if (await isMOBI(file)) {
      const fflate = await import('./vendor/fflate.js')
      book = await new MOBI({ unzlib: fflate.unzlibSync }).open(file)
    } else if (isFB2(file)) {
      const { makeFB2 } = await import('./fb2.js')
      book = await makeFB2(file)
    }
  }
  if (!book) throw new Error('File type not supported')
  const view = document.createElement('foliate-view')
  document.body.append(view)
  await view.open(book)
  return view
}

const getCSS = ({ fontSize,
  fontName,
  fontPath,
  letterSpacing,
  spacing,
  textIndent,
  paragraphSpacing,
  fontColor,
  backgroundColor,
  justify,
  hyphenate }) => {

  const fontFamily = fontName === 'book' ? '' :
    fontName === 'system' ? 'font-family: system-ui !important;' :
      `font-family: ${fontName} !important;`


  return `
    @namespace epub "http://www.idpf.org/2007/ops";
    @font-face {
      font-family: ${fontName};
      src: url('${fontPath}');
      font-display: swap;
    }

    html {
        color: ${fontColor} !important;
        background: none !important;
        // background-color: ${backgroundColor} !important;
        background-color: transparent !important;
        letter-spacing: ${letterSpacing}px;
        font-size: ${fontSize}em;
    }

    body {
        background: none !important;
        background-color: transparent;
    }

    a:link {
        color: #66ccff !important;
    }

    * {
        line-height: ${spacing}em !important;
        ${fontFamily}
    }

    p, li, blockquote, dd, div, font {
        color: ${fontColor} !important;
        // line-height: ${spacing} !important;
        padding-bottom: ${paragraphSpacing}em !important;
        text-align: ${justify ? 'justify' : 'start'};
        -webkit-hyphens: ${hyphenate ? 'auto' : 'manual'};
        hyphens: ${hyphenate ? 'auto' : 'manual'};
        -webkit-hyphenate-limit-before: 3;
        -webkit-hyphenate-limit-after: 2;
        -webkit-hyphenate-limit-lines: 2;
        hanging-punctuation: allow-end last;
        widows: 2;
        text-indent: ${textIndent}em !important;
    }
        
    /* prevent the above from overriding the align attribute */
    [align="left"] { text-align: left; }
    [align="right"] { text-align: right; }
    [align="center"] { text-align: center; }
    [align="justify"] { text-align: justify; }

    pre {
        white-space: pre-wrap !important;
    }
    aside[epub|type~="endnote"],
    aside[epub|type~="footnote"],
    aside[epub|type~="note"],
    aside[epub|type~="rearnote"] {
        display: none;
    }
`}

const convertChinese = (mode, doc) => {
  const zh_s = '皑蔼碍爱翱袄奥坝罢摆败颁办绊帮绑镑谤剥饱宝报鲍辈贝钡狈备惫绷笔毕毙闭边编贬变辩辫鳖瘪濒滨宾摈饼拨钵铂驳卜补参蚕残惭惨灿苍舱仓沧厕侧册测层诧搀掺蝉馋谗缠铲产阐颤场尝长偿肠厂畅钞车彻尘陈衬撑称惩诚骋痴迟驰耻齿炽冲虫宠畴踌筹绸丑橱厨锄雏础储触处传疮闯创锤纯绰辞词赐聪葱囱从丛凑窜错达带贷担单郸掸胆惮诞弹当挡党荡档捣岛祷导盗灯邓敌涤递缔点垫电淀钓调迭谍叠钉顶锭订东动栋冻斗犊独读赌镀锻断缎兑队对吨顿钝夺鹅额讹恶饿儿尔饵贰发罚阀珐矾钒烦范贩饭访纺飞废费纷坟奋愤粪丰枫锋风疯冯缝讽凤肤辐抚辅赋复负讣妇缚该钙盖干赶秆赣冈刚钢纲岗皋镐搁鸽阁铬个给龚宫巩贡钩沟构购够蛊顾剐关观馆惯贯广规硅归龟闺轨诡柜贵刽辊滚锅国过骇韩汉阂鹤贺横轰鸿红后壶护沪户哗华画划话怀坏欢环还缓换唤痪焕涣黄谎挥辉毁贿秽会烩汇讳诲绘荤浑伙获货祸击机积饥讥鸡绩缉极辑级挤几蓟剂济计记际继纪夹荚颊贾钾价驾歼监坚笺间艰缄茧检碱硷拣捡简俭减荐槛鉴践贱见键舰剑饯渐溅涧浆蒋桨奖讲酱胶浇骄娇搅铰矫侥脚饺缴绞轿较秸阶节茎惊经颈静镜径痉竞净纠厩旧驹举据锯惧剧鹃绢杰洁结诫届紧锦仅谨进晋烬尽劲荆觉决诀绝钧军骏开凯颗壳课垦恳抠库裤夸块侩宽矿旷况亏岿窥馈溃扩阔蜡腊莱来赖蓝栏拦篮阑兰澜谰揽览懒缆烂滥捞劳涝乐镭垒类泪篱离里鲤礼丽厉励砾历沥隶俩联莲连镰怜涟帘敛脸链恋炼练粮凉两辆谅疗辽镣猎临邻鳞凛赁龄铃凌灵岭领馏刘龙聋咙笼垄拢陇楼娄搂篓芦卢颅庐炉掳卤虏鲁赂禄录陆驴吕铝侣屡缕虑滤绿峦挛孪滦乱抡轮伦仑沦纶论萝罗逻锣箩骡骆络妈玛码蚂马骂吗买麦卖迈脉瞒馒蛮满谩猫锚铆贸么霉没镁门闷们锰梦谜弥觅绵缅庙灭悯闽鸣铭谬谋亩钠纳难挠脑恼闹馁腻撵捻酿鸟聂啮镊镍柠狞宁拧泞钮纽脓浓农疟诺欧鸥殴呕沤盘庞国爱赔喷鹏骗飘频贫苹凭评泼颇扑铺朴谱脐齐骑岂启气弃讫牵扦钎铅迁签谦钱钳潜浅谴堑枪呛墙蔷强抢锹桥乔侨翘窍窃钦亲轻氢倾顷请庆琼穷趋区躯驱龋颧权劝却鹊让饶扰绕热韧认纫荣绒软锐闰润洒萨鳃赛伞丧骚扫涩杀纱筛晒闪陕赡缮伤赏烧绍赊摄慑设绅审婶肾渗声绳胜圣师狮湿诗尸时蚀实识驶势释饰视试寿兽枢输书赎属术树竖数帅双谁税顺说硕烁丝饲耸怂颂讼诵擞苏诉肃虽绥岁孙损笋缩琐锁獭挞抬摊贪瘫滩坛谭谈叹汤烫涛绦腾誊锑题体屉条贴铁厅听烃铜统头图涂团颓蜕脱鸵驮驼椭洼袜弯湾顽万网韦违围为潍维苇伟伪纬谓卫温闻纹稳问瓮挝蜗涡窝呜钨乌诬无芜吴坞雾务误锡牺袭习铣戏细虾辖峡侠狭厦锨鲜纤咸贤衔闲显险现献县馅羡宪线厢镶乡详响项萧销晓啸蝎协挟携胁谐写泻谢锌衅兴汹锈绣虚嘘须许绪续轩悬选癣绚学勋询寻驯训讯逊压鸦鸭哑亚讶阉烟盐严颜阎艳厌砚彦谚验鸯杨扬疡阳痒养样瑶摇尧遥窑谣药爷页业叶医铱颐遗仪彝蚁艺亿忆义诣议谊译异绎荫阴银饮樱婴鹰应缨莹萤营荧蝇颖哟拥佣痈踊咏涌优忧邮铀犹游诱舆鱼渔娱与屿语吁御狱誉预驭鸳渊辕园员圆缘远愿约跃钥岳粤悦阅云郧匀陨运蕴酝晕韵杂灾载攒暂赞赃脏凿枣灶责择则泽贼赠扎札轧铡闸诈斋债毡盏斩辗崭栈战绽张涨帐账胀赵蛰辙锗这贞针侦诊镇阵挣睁狰帧郑证织职执纸挚掷帜质钟终种肿众诌轴皱昼骤猪诸诛烛瞩嘱贮铸筑驻专砖转赚桩庄装妆壮状锥赘坠缀谆浊兹资渍踪综总纵邹诅组钻致钟么为只凶准启板里雳余链泄';
  const zh_t = '皚藹礙愛翺襖奧壩罷擺敗頒辦絆幫綁鎊謗剝飽寶報鮑輩貝鋇狽備憊繃筆畢斃閉邊編貶變辯辮鼈癟瀕濱賓擯餅撥缽鉑駁蔔補參蠶殘慚慘燦蒼艙倉滄廁側冊測層詫攙摻蟬饞讒纏鏟産闡顫場嘗長償腸廠暢鈔車徹塵陳襯撐稱懲誠騁癡遲馳恥齒熾沖蟲寵疇躊籌綢醜櫥廚鋤雛礎儲觸處傳瘡闖創錘純綽辭詞賜聰蔥囪從叢湊竄錯達帶貸擔單鄲撣膽憚誕彈當擋黨蕩檔搗島禱導盜燈鄧敵滌遞締點墊電澱釣調叠諜疊釘頂錠訂東動棟凍鬥犢獨讀賭鍍鍛斷緞兌隊對噸頓鈍奪鵝額訛惡餓兒爾餌貳發罰閥琺礬釩煩範販飯訪紡飛廢費紛墳奮憤糞豐楓鋒風瘋馮縫諷鳳膚輻撫輔賦複負訃婦縛該鈣蓋幹趕稈贛岡剛鋼綱崗臯鎬擱鴿閣鉻個給龔宮鞏貢鈎溝構購夠蠱顧剮關觀館慣貫廣規矽歸龜閨軌詭櫃貴劊輥滾鍋國過駭韓漢閡鶴賀橫轟鴻紅後壺護滬戶嘩華畫劃話懷壞歡環還緩換喚瘓煥渙黃謊揮輝毀賄穢會燴彙諱誨繪葷渾夥獲貨禍擊機積饑譏雞績緝極輯級擠幾薊劑濟計記際繼紀夾莢頰賈鉀價駕殲監堅箋間艱緘繭檢堿鹼揀撿簡儉減薦檻鑒踐賤見鍵艦劍餞漸濺澗漿蔣槳獎講醬膠澆驕嬌攪鉸矯僥腳餃繳絞轎較稭階節莖驚經頸靜鏡徑痙競淨糾廄舊駒舉據鋸懼劇鵑絹傑潔結誡屆緊錦僅謹進晉燼盡勁荊覺決訣絕鈞軍駿開凱顆殼課墾懇摳庫褲誇塊儈寬礦曠況虧巋窺饋潰擴闊蠟臘萊來賴藍欄攔籃闌蘭瀾讕攬覽懶纜爛濫撈勞澇樂鐳壘類淚籬離裏鯉禮麗厲勵礫曆瀝隸倆聯蓮連鐮憐漣簾斂臉鏈戀煉練糧涼兩輛諒療遼鐐獵臨鄰鱗凜賃齡鈴淩靈嶺領餾劉龍聾嚨籠壟攏隴樓婁摟簍蘆盧顱廬爐擄鹵虜魯賂祿錄陸驢呂鋁侶屢縷慮濾綠巒攣孿灤亂掄輪倫侖淪綸論蘿羅邏鑼籮騾駱絡媽瑪碼螞馬罵嗎買麥賣邁脈瞞饅蠻滿謾貓錨鉚貿麽黴沒鎂門悶們錳夢謎彌覓綿緬廟滅憫閩鳴銘謬謀畝鈉納難撓腦惱鬧餒膩攆撚釀鳥聶齧鑷鎳檸獰甯擰濘鈕紐膿濃農瘧諾歐鷗毆嘔漚盤龐國愛賠噴鵬騙飄頻貧蘋憑評潑頗撲鋪樸譜臍齊騎豈啓氣棄訖牽扡釺鉛遷簽謙錢鉗潛淺譴塹槍嗆牆薔強搶鍬橋喬僑翹竅竊欽親輕氫傾頃請慶瓊窮趨區軀驅齲顴權勸卻鵲讓饒擾繞熱韌認紉榮絨軟銳閏潤灑薩鰓賽傘喪騷掃澀殺紗篩曬閃陝贍繕傷賞燒紹賒攝懾設紳審嬸腎滲聲繩勝聖師獅濕詩屍時蝕實識駛勢釋飾視試壽獸樞輸書贖屬術樹豎數帥雙誰稅順說碩爍絲飼聳慫頌訟誦擻蘇訴肅雖綏歲孫損筍縮瑣鎖獺撻擡攤貪癱灘壇譚談歎湯燙濤縧騰謄銻題體屜條貼鐵廳聽烴銅統頭圖塗團頹蛻脫鴕馱駝橢窪襪彎灣頑萬網韋違圍爲濰維葦偉僞緯謂衛溫聞紋穩問甕撾蝸渦窩嗚鎢烏誣無蕪吳塢霧務誤錫犧襲習銑戲細蝦轄峽俠狹廈鍁鮮纖鹹賢銜閑顯險現獻縣餡羨憲線廂鑲鄉詳響項蕭銷曉嘯蠍協挾攜脅諧寫瀉謝鋅釁興洶鏽繡虛噓須許緒續軒懸選癬絢學勳詢尋馴訓訊遜壓鴉鴨啞亞訝閹煙鹽嚴顔閻豔厭硯彥諺驗鴦楊揚瘍陽癢養樣瑤搖堯遙窯謠藥爺頁業葉醫銥頤遺儀彜蟻藝億憶義詣議誼譯異繹蔭陰銀飲櫻嬰鷹應纓瑩螢營熒蠅穎喲擁傭癰踴詠湧優憂郵鈾猶遊誘輿魚漁娛與嶼語籲禦獄譽預馭鴛淵轅園員圓緣遠願約躍鑰嶽粵悅閱雲鄖勻隕運蘊醞暈韻雜災載攢暫贊贓髒鑿棗竈責擇則澤賊贈紮劄軋鍘閘詐齋債氈盞斬輾嶄棧戰綻張漲帳賬脹趙蟄轍鍺這貞針偵診鎮陣掙睜猙幀鄭證織職執紙摯擲幟質鍾終種腫衆謅軸皺晝驟豬諸誅燭矚囑貯鑄築駐專磚轉賺樁莊裝妝壯狀錐贅墜綴諄濁茲資漬蹤綜總縱鄒詛組鑽緻鐘麼為隻兇準啟闆裡靂餘鍊洩';

  const from = mode === 's2t' ? zh_s : zh_t
  const to = mode === 's2t' ? zh_t : zh_s

  const convertTextNode = (node, from, to) => {
    if (node.nodeType === Node.TEXT_NODE) {
      node.textContent = node.textContent.replace(/[\u4e00-\u9fa5]/g, (match) => {
        return to[from.indexOf(match)] ?? match
      });
    } else {
      node.childNodes.forEach(child => convertTextNode(child, from, to));
    }
  };

  doc.body.childNodes.forEach(node => {
    convertTextNode(node, from, to);
  });
}


const footnoteDialog = document.getElementById('footnote-dialog')
footnoteDialog.addEventListener('close', () => {
  callFlutter("onFootnoteClose")
})

const replaceFootnote = (view) => {
  clearSelection()
  footnoteDialog.querySelector('main').replaceChildren(view)

  view.addEventListener('load', (e) => {
    const { doc, index } = e.detail
    globalThis.footnoteSelection = () => handleSelection(view, doc, index)
    setSelectionHandler(view, doc, index)
    convertChinese(convertChineseMode, doc)

    setTimeout(() => {
      const dialog = document.getElementById('footnote-dialog')
      const content = document.querySelector("#footnote-dialog > div > main > foliate-view")
        .shadowRoot.querySelector("foliate-paginator")
        .shadowRoot.querySelector("#container > div > iframe")


      dialog.style.width = 'auto'
      dialog.style.height = 'auto'

      const contentWidth = content.scrollWidth
      const contentHeight = content.scrollHeight

      dialog.style.width = `${Math.min(Math.max(contentWidth, 200), window.innerWidth * 0.8)}px`
      dialog.style.height = `${Math.min(Math.max(contentHeight, 100), window.innerHeight * 0.8)}px`
    }, 0)
  })

  const { renderer } = view
  renderer.setAttribute('flow', 'scrolled')
  renderer.setAttribute('gap', '5%')
  const footNoteStyle = {
    fontSize: style.fontSize,
    fontName: style.fontName,
    fontPath: style.fontPath,
    letterSpacing: style.letterSpacing,
    spacing: style.spacing,
    textIndent: style.textIndent,
    fontColor: style.fontColor,
    backgroundColor: 'transparent',
    justify: true,
    hyphenate: true,
  }
  renderer.setStyles(getCSS(footNoteStyle))
  // set background color of dialog
  // if #rrggbbaa, replace aa to ee
  footnoteDialog.style.backgroundColor = style.backgroundColor.slice(0, 7) + 'ee'
}
footnoteDialog.addEventListener('click', e =>
  e.target === footnoteDialog ? footnoteDialog.close() : null)

class Reader {
  annotations = new Map()
  annotationsByValue = new Map()
  #footnoteHandler = new FootnoteHandler()
  #doc
  #index
  #originalContent
  constructor() {
    this.#footnoteHandler.addEventListener('before-render', e => {
      const { view } = e.detail
      this.setView(view)
      replaceFootnote(view)
    })
    this.#footnoteHandler.addEventListener('render', e => {
      const { view } = e.detail
      footnoteDialog.showModal()
    })
    this.#originalContent = null
  }
  async open(file, cfi) {
    this.view = await getView(file, cfi)

    if (importing) return

    this.view.addEventListener('load', this.#onLoad.bind(this))
    this.view.addEventListener('relocate', this.#onRelocate.bind(this))
    this.view.addEventListener('click-view', this.#onClickView.bind(this))

    setStyle()
    if (!cfi)
      this.view.renderer.next()
    this.setView(this.view)
    await this.view.init({ lastLocation: cfi })
  }

  setView(view) {
    view.addEventListener('create-overlay', e => {
      const { index } = e.detail
      const list = this.annotations.get(index)
      if (list) for (const annotation of list)
        this.view.addAnnotation(annotation)
    })

    view.addEventListener('draw-annotation', e => {
      const { draw, annotation } = e.detail
      const { color, type } = annotation
      if (type === 'highlight') draw(Overlayer.highlight, { color })
      else if (type === 'underline') draw(Overlayer.underline, { color })
    })

    view.addEventListener('show-annotation', e => {
      const annotation = this.annotationsByValue.get(e.detail.value)
      const pos = getPosition(e.detail.range)
      onAnnotationClick({ annotation, pos })
    })
    view.addEventListener('external-link', e => {
      e.preventDefault()
      onExternalLink(e.detail)
    })

    view.addEventListener('link', e =>
      this.#footnoteHandler.handle(this.view.book, e)?.catch(err => {
        console.warn(err)
        this.view.goTo(e.detail.href)
      }))

    view.history.addEventListener('pushstate', e => {
      callFlutter('onPushState', {
        canGoBack: view.history.canGoBack,
        canGoForward: view.history.canGoForward
      })
    })
    view.addEventListener('click-image', async e => {
      console.log('click-image', e.detail.img.src)
      const blobUrl = e.detail.img.src
      const blob = await fetch(blobUrl).then(r => r.blob())
      const base64 = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onloadend = () => resolve(reader.result)
        reader.onerror = reject
        reader.readAsDataURL(blob)
      })
      callFlutter('onImageClick', base64)
    })
  }

  renderAnnotation() {
    const bookmarks = allAnnotations ?? []
    for (const bookmark of bookmarks) {
      const { value, type, color, note } = bookmark
      const annotation = {
        id: bookmark.id,
        value,
        type,
        color,
        note
      }

      this.addAnnotation(annotation)
    }

  }

  showContextMenu() {
    return handleSelection(this.view, this.#doc, this.#index)
  }

  addAnnotation(annotation) {
    const { value } = annotation
    const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

    const list = this.annotations.get(spineCode)
    if (list) list.push(annotation)
    else this.annotations.set(spineCode, [annotation])

    this.annotationsByValue.set(value, annotation)

    this.view.addAnnotation(annotation)
  }

  removeAnnotation(cfi) {
    const annotation = this.annotationsByValue.get(cfi)
    const { value } = annotation
    const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

    const list = this.annotations.get(spineCode)
    if (list) {
      const index = list.findIndex(a => a.id === annotation.id)
      if (index !== -1) list.splice(index, 1)
    }

    this.annotationsByValue.delete(value)

    this.view.addAnnotation(annotation, true)
  }

  #onLoad({ detail: { doc, index } }) {
    this.#doc = doc
    this.#index = index
    // this.#originalContent = doc.body.innerHTML
    setSelectionHandler(this.view, doc, index)
    this.convertChinese(convertChineseMode)
  }

  #onRelocate({ detail }) {
    const { cfi, fraction, location, tocItem, pageItem, chapterLocation } = detail
    const loc = pageItem
      ? `Page ${pageItem.label}`
      : `Loc ${location.current}`
    onRelocated({ cfi, fraction, loc, tocItem, pageItem, location, chapterLocation })
  }

  #onClickView({ detail: { x, y } }) {
    const coordinatesX = x / window.innerWidth
    const coordinatesY = y / window.innerHeight
    onClickView(coordinatesX, coordinatesY)
  }

  get index() {
    return this.#index
  }

  convertChinese = (mode) => {
    if (mode === 'none') {
      if (this.#originalContent) {
        const walker = document.createTreeWalker(
          this.#doc.body,
          NodeFilter.SHOW_TEXT,
          null,
          false
        );
        let node;
        let index = 0;
        while (node = walker.nextNode()) {
          node.textContent = this.#originalContent[index++];
        }
      }
      return;
    }

    // save original content
    if (!this.#originalContent) {
      this.#originalContent = [];
      const walker = document.createTreeWalker(
        this.#doc.body,
        NodeFilter.SHOW_TEXT,
        null,
        false
      );
      while (walker.nextNode()) {
        this.#originalContent.push(walker.currentNode.textContent);
      }
    }
    convertChinese(mode, this.#doc)
  }
}

const open = async (file, cfi) => {
  const reader = new Reader()
  globalThis.reader = reader
  await reader.open(file, cfi)
  if (!importing) {
    onSetToc()
    callFlutter('renderAnnotations')
  }
  else { getMetadata() }
}


const callFlutter = (name, data) => window.flutter_inappwebview.callHandler(name, data)

const setStyle = () => {
  const turn = {
    scroll: false,
    animated: true
  }

  switch (style.pageTurnStyle) {
    case 'slide':
      turn.scroll = false
      turn.animated = true
      break
    case 'scroll':
      turn.scroll = true
      turn.animated = true
      break
    case "noAnimation":
      turn.scroll = false
      turn.animated = false
      break
  }

  reader.view.renderer.setAttribute('flow', turn.scroll ? 'scrolled' : 'paginated')
  reader.view.renderer.setAttribute('top-margin', `${style.topMargin}px`)
  reader.view.renderer.setAttribute('bottom-margin', `${style.bottomMargin}px`)
  reader.view.renderer.setAttribute('gap', `${style.sideMargin}%`)
  reader.view.renderer.setAttribute('background-color', style.backgroundColor)

  turn.animated ? reader.view.renderer.setAttribute('animated', 'true')
    : reader.view.renderer.removeAttribute('animated')

  const newStyle = {
    fontSize: style.fontSize,
    fontName: style.fontName,
    fontPath: style.fontPath,
    letterSpacing: style.letterSpacing,
    spacing: style.spacing,
    paragraphSpacing: style.paragraphSpacing,
    textIndent: style.textIndent,
    fontColor: style.fontColor,
    backgroundColor: style.backgroundColor,
    justify: style.justify,
    hyphenate: style.hyphenate
  }
  reader.view.renderer.setStyles?.(getCSS(newStyle))
}

const onRelocated = (currentInfo) => {
  const chapterTitle = currentInfo.tocItem?.label
  const chapterHref = currentInfo.tocItem?.href
  const chapterTotalPages = currentInfo.chapterLocation.total
  const chapterCurrentPage = currentInfo.chapterLocation.current
  const bookTotalPages = currentInfo.location.total
  const bookCurrentPage = currentInfo.location.current
  const cfi = currentInfo.cfi
  const percentage = currentInfo.fraction

  callFlutter('onRelocated', {
    chapterTitle,
    chapterHref,
    chapterTotalPages,
    chapterCurrentPage,
    bookTotalPages,
    bookCurrentPage,
    cfi,
    percentage
  })
}

const onAnnotationClick = (annotation) => callFlutter('onAnnotationClick', annotation)

const onClickView = (x, y) => callFlutter('onClick', { x, y })

const onExternalLink = (link) => console.log(link)

const onSetToc = () => callFlutter('onSetToc', reader.view.book.toc)

const getMetadata = async () => {
  const cover = await reader.view.book.getCover()
  if (cover) {
    // cover is a blob, so we need to convert it to base64
    const fileReader = new FileReader()
    fileReader.readAsDataURL(cover)
    fileReader.onloadend = () => {
      callFlutter('onMetadata', {
        ...reader.view.book.metadata,
        cover: fileReader.result
      })
    }
  } else {
    callFlutter('onMetadata', {
      ...reader.view.book.metadata,
      cover: null
    })
  }
}

window.changeStyle = (newStyle) => {
  style = {
    ...style,
    ...newStyle
  }
  console.log('changeStyle', JSON.stringify(style))
  setStyle()
}

window.goToHref = href => reader.view.goTo(href)

window.goToCfi = cfi => reader.view.goTo(cfi)

window.goToPercent = percent => reader.view.goToFraction(percent)

window.nextPage = () => reader.view.next()

window.prevPage = () => reader.view.prev()

window.setScroll = () => {
  style.scroll = true
  style.animated = true
  setStyle()
}

window.setPaginated = () => {
  style.scroll = false
  style.animated = true
  setStyle()
}

window.setNoAnimation = () => {
  style.scroll = false
  style.animated = false
  setStyle()
}

const onSelectionEnd = (selection) => {
  if (footnoteDialog.open) {
    callFlutter('onSelectionEnd', { ...selection, footnote: true })
  } else {
    callFlutter('onSelectionEnd', { ...selection, footnote: false })
  }
}

window.showContextMenu = () => {
  if (footnoteDialog.open) {
    footnoteSelection()
  } else {
    reader.showContextMenu()
  }
}

window.clearSelection = () => reader.view.deselect()

window.addAnnotation = (annotation) => reader.addAnnotation(annotation)

window.removeAnnotation = (cfi) => reader.removeAnnotation(cfi)

window.prevSection = () => reader.view.renderer.prevSection()

window.nextSection = () => reader.view.renderer.nextSection()

window.initTts = () => reader.view.initTTS()

window.ttsStop = () => reader.view.initTTS(true)

window.ttsHere = () => {
  initTts()
  return reader.view.tts.from(reader.view.lastLocation.range)
}

window.ttsNextSection = async () => {
  await nextSection()
  initTts()
  return ttsNext()
}

window.ttsPrevSection = async (last) => {
  await prevSection()
  initTts()
  return last ? reader.view.tts.end() : ttsNext()
}

window.ttsNext = async () => {
  const result = reader.view.tts.next(true)
  if (result) return result
  return await ttsNextSection()
}

window.ttsPrev = () => {
  const result = reader.view.tts.prev(true)
  if (result) return result
  return ttsPrevSection(true)
}

window.ttsPrepare = () => reader.view.tts.prepare()

window.clearSearch = () => reader.view.clearSearch()

window.search = async (text, opts) => {
  opts == null && (opts = {
    'scope': 'book',
    'matchCase': false,
    'matchDiacritics': false,
    'matchWholeWords': false,
  })
  const query = text.trim()
  if (!query) return

  const index = opts.scope === 'section' ? reader.index : null

  for await (const result of reader.view.search({ ...opts, query, index })) {
    if (result === 'done') {
      callFlutter('onSearch', { process: 1.0 })
    }
    else if ('progress' in result)
      callFlutter('onSearch', { process: result.progress })
    else {
      callFlutter('onSearch', result)
    }
  }
}

window.back = () => reader.view.history.back()

window.forward = () => reader.view.history.forward()

window.renderAnnotations = () => reader.renderAnnotation()

window.convertChinese = (mode) => reader.convertChinese(mode)

await callFlutter('webviewInitialVariable')

fetch(url)
  .then(res => res.blob())
  .then(blob => open(new File([blob], new URL(url, window.location.origin).pathname), initialCfi))
  .catch(e => console.error(e))
