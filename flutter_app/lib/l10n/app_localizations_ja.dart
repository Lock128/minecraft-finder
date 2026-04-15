// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '鉱石・構造物ファインダー';

  @override
  String get appTitleFull => 'MC用 鉱石・構造物ファインダー — ダイヤモンド、金、ネザライトなどを発見';

  @override
  String get searchTab => '検索';

  @override
  String get resultsTab => '結果';

  @override
  String get guideTab => 'ガイド';

  @override
  String get bedwarsTab => 'ベッドウォーズ';

  @override
  String get updatesTab => '更新情報';

  @override
  String get appInfoTooltip => 'アプリ情報';

  @override
  String get lightThemeTooltip => 'ライト';

  @override
  String get darkThemeTooltip => 'ダーク';

  @override
  String get languageTooltip => '言語';

  @override
  String get errorEnableSearchType => '少なくとも1つの検索タイプ（鉱石または構造物）を有効にしてください';

  @override
  String get errorSelectStructure => '少なくとも1つの構造物タイプを選択してください';

  @override
  String get errorSelectOre => '少なくとも1つの鉱石タイプを選択してください';

  @override
  String errorGeneric(String message) {
    return 'エラー: $message';
  }

  @override
  String get worldSettingsTitle => 'ワールド設定';

  @override
  String get worldSeedLabel => 'ワールドシード';

  @override
  String get worldSeedHint => 'ワールドシードを入力';

  @override
  String get errorEmptySeed => 'ワールドシードを入力してください';

  @override
  String get recentSeeds => '最近のシード';

  @override
  String get searchCenterTitle => '検索中心';

  @override
  String get coordinateX => 'X';

  @override
  String get coordinateY => 'Y';

  @override
  String get coordinateZ => 'Z';

  @override
  String get searchRadiusLabel => '検索半径（ブロック）';

  @override
  String get errorEmptyRadius => '検索半径を入力してください';

  @override
  String get errorRadiusPositive => '半径は正の数にしてください';

  @override
  String get errorRadiusMax => '最大2000';

  @override
  String get errorFieldRequired => '必須';

  @override
  String get errorFieldInvalid => '無効';

  @override
  String get errorYRange => '-64〜320';

  @override
  String get togglePlusMinus => '+/- 切替';

  @override
  String get oreTypeTitle => '鉱石タイプ';

  @override
  String get includeOresInSearch => '鉱石を検索に含める';

  @override
  String get includeNetherGold => 'ネザーゴールドを含める';

  @override
  String get searchForNetherGold => 'ネザー金鉱石を検索';

  @override
  String get netheriteAncientDebris => 'ネザライト（古代の残骸）';

  @override
  String get legendDiamond => '💎 ダイヤモンド';

  @override
  String get legendGold => '🏅 金';

  @override
  String get legendIron => '⚪ 鉄';

  @override
  String get legendRedstone => '🔴 レッドストーン';

  @override
  String get legendCoal => '⚫ 石炭';

  @override
  String get legendLapis => '🔵 ラピスラズリ';

  @override
  String get structureSearchTitle => '構造物検索';

  @override
  String get includeStructuresInSearch => '構造物を検索に含める';

  @override
  String get selectStructuresToFind => '検索する構造物を選択:';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get clearAll => 'すべて解除';

  @override
  String structuresSelected(int count) {
    return '$count個の構造物を選択中';
  }

  @override
  String get findButton => '検索';

  @override
  String get findAllNetheriteButton => '全ネザライト検索';

  @override
  String get searchingButton => '検索中...';

  @override
  String get comprehensiveNetheriteSearch => '包括的ネザライト検索';

  @override
  String get comprehensiveNetheriteBody =>
      '• ワールド全体を検索（4000×4000ブロック）\n• 30〜60秒かかる場合があります\n• 最大300箇所の最適な場所を表示\n• 他の鉱石選択は無視されます';

  @override
  String get regularSearchInfo => '通常検索は上位250件の結果を表示します（全タイプ合計）';

  @override
  String get loadingNetherite => '包括的ネザライト検索を実行中...';

  @override
  String get loadingAnalyzing => 'ワールド生成を解析中...';

  @override
  String get loadingTimeMay => '30〜60秒かかる場合があります';

  @override
  String get noResultsYet => 'まだ結果がありません';

  @override
  String get useSearchTabToFind => '検索タブから鉱石を探しましょう';

  @override
  String get noResultsMatchFilters => 'フィルターに一致する結果がありません';

  @override
  String get tryAdjustingFilters => 'フィルター設定を調整してみてください';

  @override
  String resultsCount(int total, int oreCount, int structureCount) {
    return '$total件の結果 · $oreCount件の鉱石 · $structureCount件の構造物';
  }

  @override
  String get hideFilters => 'フィルターを隠す';

  @override
  String get showFilters => 'フィルターを表示';

  @override
  String get oreFiltersLabel => '鉱石フィルター:';

  @override
  String get filterDiamonds => '💎 ダイヤモンド';

  @override
  String get filterGold => '🏅 金';

  @override
  String get filterIron => '⚪ 鉄';

  @override
  String get filterRedstone => '🔴 レッドストーン';

  @override
  String get filterCoal => '⚫ 石炭';

  @override
  String get filterLapis => '🔵 ラピスラズリ';

  @override
  String get filterNetherite => '🔥 ネザライト';

  @override
  String get structureFiltersLabel => '構造物フィルター:';

  @override
  String get biomeFiltersLabel => 'バイオームフィルター:';

  @override
  String get coordinateFiltersTitle => '座標フィルター';

  @override
  String get minX => '最小X';

  @override
  String get maxX => '最大X';

  @override
  String get minY => '最小Y';

  @override
  String get maxY => '最大Y';

  @override
  String get minZ => '最小Z';

  @override
  String get maxZ => '最大Z';

  @override
  String get clearAllFilters => 'すべてのフィルターをクリア';

  @override
  String get copyCoordinates => '座標をコピー';

  @override
  String copiedCoordinates(String coords) {
    return '座標をコピーしました: $coords';
  }

  @override
  String chunkLabel(int chunkX, int chunkZ) {
    return 'チャンク: ($chunkX, $chunkZ)';
  }

  @override
  String probabilityLabel(String percent) {
    return '確率: $percent%';
  }

  @override
  String biomeLabel(String biome) {
    return 'バイオーム: $biome';
  }

  @override
  String get guideDiamondTitle => 'ダイヤモンドの生成';

  @override
  String get guideDiamondIntro => 'ダイヤモンドはオーバーワールドのY -64からY 16の間に生成されます。';

  @override
  String get guideDiamondOptimal => '🎯 最適なY座標:';

  @override
  String get guideDiamondLevel1 => '• Y -64〜-54: ダイヤモンド最多層（基本確率80%）';

  @override
  String get guideDiamondLevel2 => '• Y -53〜-48: ダイヤモンド良好層（基本確率60%）';

  @override
  String get guideDiamondLevel3 => '• Y -47〜-32: ダイヤモンド普通層（基本確率40%）';

  @override
  String get guideDiamondLevel4 => '• Y -31〜16: ダイヤモンド低確率層（基本確率20%）';

  @override
  String get guideGoldTitle => '金の生成';

  @override
  String get guideGoldIntro => '金はバイオームとディメンションによって異なる生成パターンを持ちます。';

  @override
  String get guideGoldOverworld => '🌍 オーバーワールドの金（Y -64〜32）:';

  @override
  String get guideGoldLevel1 => '• Y -47〜-16: 金最多層（基本確率60%）';

  @override
  String get guideGoldLevel2 => '• Y -64〜-48: 低層（基本確率40%）';

  @override
  String get guideGoldLevel3 => '• Y -15〜32: 高層（基本確率30%）';

  @override
  String get guideGoldBadlands => '🏜️ 荒野（メサ）バイオーム（ボーナス！）:';

  @override
  String get guideGoldBadlandsLevel => '• Y 32〜80: 優れた地表金（基本確率90%）';

  @override
  String get guideGoldBadlandsBonus => '• 通常バイオームの6倍の金！';

  @override
  String get guideNetheriteTitle => 'ネザライト（古代の残骸）';

  @override
  String get guideNetheriteIntro => '古代の残骸はネザーにのみ存在する最も希少な鉱石です。';

  @override
  String get guideNetheriteOptimal => '🎯 ネザーのY座標（Y 8〜22）:';

  @override
  String get guideNetheriteLevel1 => '• Y 13〜17: 古代の残骸最多層（基本確率90%）';

  @override
  String get guideNetheriteLevel2 => '• Y 10〜19: 古代の残骸良好層（基本確率70%）';

  @override
  String get guideNetheriteLevel3 => '• Y 8〜22: 古代の残骸普通層（基本確率50%）';

  @override
  String get guideNetheriteSearch => '🔍 検索モード:';

  @override
  String get guideNetheriteRegular => '• 通常検索: 最低確率15%のしきい値を使用';

  @override
  String get guideNetheriteComprehensive =>
      '• 包括的検索: 5%のしきい値を使用、4000×4000ブロックをカバー';

  @override
  String get guideIronTitle => '鉄の生成';

  @override
  String get guideIronIntro => '鉄は最も汎用性が高く一般的な鉱石の一つです。';

  @override
  String get guideIronOptimal => '🎯 最適なY座標:';

  @override
  String get guideIronLevel1 => '• Y 128〜256: 山岳の鉄生成（Y 232でピーク）';

  @override
  String get guideIronLevel2 => '• Y -24〜56: 地下の鉄生成（Y 15でピーク）';

  @override
  String get guideIronLevel3 => '• Y -64〜72: 一般的な鉄の分布（基本確率40%）';

  @override
  String get guideRedstoneTitle => 'レッドストーンの生成';

  @override
  String get guideRedstoneIntro => 'レッドストーンは自動化や複雑な装置の鍵となります。';

  @override
  String get guideRedstoneOptimal => '🎯 最適なY座標（Y -64〜15）:';

  @override
  String get guideRedstoneLevel1 => '• Y -64〜-59: レッドストーン最多層（基本確率90%）';

  @override
  String get guideRedstoneLevel2 => '• Y -58〜-48: レッドストーン良好層（基本確率70%）';

  @override
  String get guideRedstoneLevel3 => '• Y -47〜-32: レッドストーン普通層（基本確率50%）';

  @override
  String get guideRedstoneLevel4 => '• Y -31〜15: レッドストーン低確率層（基本確率30%）';

  @override
  String get guideCoalTitle => '石炭の生成';

  @override
  String get guideCoalIntro => '石炭は最も一般的な鉱石であり、主要な燃料源です。';

  @override
  String get guideCoalOptimal => '🎯 最適なY座標（Y 0〜256）:';

  @override
  String get guideCoalLevel1 => '• Y 80〜136: 石炭最多生成（Y 96でピーク）';

  @override
  String get guideCoalLevel2 => '• Y 0〜256: 一般的な石炭の分布（基本確率60%）';

  @override
  String get guideLapisTitle => 'ラピスラズリの生成';

  @override
  String get guideLapisIntro => 'ラピスラズリはオーバーワールドのY -64からY 64の間に生成されます。';

  @override
  String get guideLapisOptimal => '🎯 最適なY座標:';

  @override
  String get guideLapisLevel1 => '• Y 0〜32: ラピスラズリ最多層（強化生成）';

  @override
  String get guideLapisLevel2 => '• Y -64〜-1: 低層（通常生成）';

  @override
  String get guideLapisLevel3 => '• Y 33〜64: 高層（減少生成）';

  @override
  String get guideStructureTitle => '構造物の生成';

  @override
  String get guideStructureIntro => '構造物はバイオームの適合性と希少度に基づいて生成されます。';

  @override
  String get guideStructureCommon => '🏘️ 一般的な構造物（高い出現率）:';

  @override
  String get guideStructureVillages => '• 村: 平原、砂漠、サバンナ、タイガバイオーム';

  @override
  String get guideStructureOutposts => '• ピリジャーの前哨基地: 村と同じバイオーム';

  @override
  String get guideStructurePortals => '• 荒廃したポータル: どのディメンションにも出現可能';

  @override
  String get guideStructureRare => '🏛️ 希少な構造物（低い出現率）:';

  @override
  String get guideStructureStrongholds => '• 要塞: 地下、ワールドに128個のみ';

  @override
  String get guideStructureEndCities => '• エンドシティ: エンドの外側の島々';

  @override
  String get guideStructureMonuments => '• 海底神殿: 深海バイオーム';

  @override
  String get guideStructureAncientCities => '• 古代都市: ディープダークバイオーム（Y -52）';

  @override
  String get proTipTitle => 'プロのヒント';

  @override
  String get proTipBody =>
      'このツールはブロックゲームの生成アルゴリズムに基づく統計的予測を提供します。座標を採掘の出発点として使用し、鉱脈を見つけたら周辺エリアも探索しましょう！';

  @override
  String get bedwarsTierStarters => '初心者';

  @override
  String get bedwarsTierPractitioners => '中級者';

  @override
  String get bedwarsTierExperts => '上級者';

  @override
  String get bedwarsGameObjectiveTitle => 'ゲームの目的とルール';

  @override
  String get bedwarsGameObjective1 => '自分のベッドを守りながら、敵のベッドを破壊しましょう。';

  @override
  String get bedwarsGameObjective2 => 'ベッドが破壊されると、リスポーンできなくなります。';

  @override
  String get bedwarsGameObjective3 => '最後まで生存者がいるチームが勝利します。';

  @override
  String get bedwarsGameObjective4 => 'ジェネレーターから資源を集めて装備やブロックを購入しましょう。';

  @override
  String get bedwarsResourceGatheringTitle => '基本的な資源収集';

  @override
  String get bedwarsResourceGathering1 => '鉄と金は島のジェネレーターで自動的に生成されます。';

  @override
  String get bedwarsResourceGathering2 => '戦闘の合間にジェネレーターの近くにいて資源を集めましょう。';

  @override
  String get bedwarsResourceGathering3 => '鉄はショップで基本的なブロックやツールに使います。';

  @override
  String get bedwarsResourceGathering4 => '金はより強力な防具、武器、ユーティリティアイテムを購入できます。';

  @override
  String get bedwarsPurchasingTitle => '必須アイテムの購入';

  @override
  String get bedwarsPurchasing1 => '橋渡しやベッド防衛のために、早めにウールやエンドストーンを購入しましょう。';

  @override
  String get bedwarsPurchasing2 => '石の剣は木の剣からの安価な初期アップグレードです。';

  @override
  String get bedwarsPurchasing3 => '鉄の防具は最初の戦闘で確実な防御力を提供します。';

  @override
  String get bedwarsPurchasing4 => 'ウール防衛を素早く切るためにハサミを入手しましょう。';

  @override
  String get bedwarsBedDefenseTitle => '基本的なベッド防衛';

  @override
  String get bedwarsBedDefense1 => 'ゲーム開始直後にベッドをウールで覆いましょう。';

  @override
  String get bedwarsBedDefense2 => 'ウールの周りにエンドストーンの第二層を追加して防御を強化しましょう。';

  @override
  String get bedwarsBedDefense3 => '序盤にベッドを完全に無防備にしないでください。';

  @override
  String get bedwarsBedDefense4 => 'ベッドの上面を含むすべての面にブロックを配置しましょう。';

  @override
  String get bedwarsCombatTipsTitle => '基本的な戦闘のコツ';

  @override
  String get bedwarsCombatTips1 => '相手を攻撃する前に必ずダッシュして追加のノックバックを与えましょう。';

  @override
  String get bedwarsCombatTips2 => '攻撃とブロックを交互に行うブロックヒットでダメージを軽減しましょう。';

  @override
  String get bedwarsCombatTips3 => 'ジャンプの落下中に攻撃してクリティカルヒットを狙いましょう。';

  @override
  String get bedwarsCombatTips4 => 'ノックバックが致命的な狭い橋での戦闘は避けましょう。';

  @override
  String get bedwarsResourceManagementTitle => '効率的な資源管理とアップグレード';

  @override
  String get bedwarsResourceManagement1 =>
      '中央の島のダイヤモンドとエメラルドのジェネレーターを定期的に訪れましょう。';

  @override
  String get bedwarsResourceManagement2 =>
      '鋭さ、防護、鍛冶アップグレードなどのチームアップグレードを優先しましょう。';

  @override
  String get bedwarsResourceManagement3 => 'チームメイトと資源収集の役割を分担して進行を早めましょう。';

  @override
  String get bedwarsResourceManagement4 =>
      'ダイヤモンド防具やエンダーパールなどの強力なアイテムのためにエメラルドを貯めましょう。';

  @override
  String get bedwarsIntermediateDefenseTitle => '中級ベッド防衛';

  @override
  String get bedwarsIntermediateDefense1 =>
      'ベッド防衛を層状に: 内側にウール、中間にエンドストーン、外側に木材またはガラス。';

  @override
  String get bedwarsIntermediateDefense2 => 'TNT攻撃に対抗するために防爆ガラスを使用しましょう。';

  @override
  String get bedwarsIntermediateDefense3 => 'ベッドの近くに水バケツを置いて攻撃者を遅らせましょう。';

  @override
  String get bedwarsIntermediateDefense4 => '最大の耐久性のために最内層に黒曜石を配置することを検討しましょう。';

  @override
  String get bedwarsTeamCoordinationTitle => 'チーム連携戦略';

  @override
  String get bedwarsTeamCoordination1 => '役割を分担: 1人が防衛し、他のメンバーが攻撃や資源収集を行いましょう。';

  @override
  String get bedwarsTeamCoordination2 => '敵の位置や攻撃をチームに伝えましょう。';

  @override
  String get bedwarsTeamCoordination3 => '最大の圧力をかけるために敵拠点への同時攻撃を調整しましょう。';

  @override
  String get bedwarsTeamCoordination4 => '特定のアップグレードが必要なチームメイトと資源を共有しましょう。';

  @override
  String get bedwarsBridgeBuildingTitle => '橋渡しテクニック';

  @override
  String get bedwarsBridgeBuilding1 => '端でしゃがみながら素早くブロックを置くスピードブリッジを練習しましょう。';

  @override
  String get bedwarsBridgeBuilding2 => '弓の射撃を避けるために少しジグザグのパターンで橋を作りましょう。';

  @override
  String get bedwarsBridgeBuilding3 => '恒久的な橋にはエンドストーンなどの壊れにくいブロックを使いましょう。';

  @override
  String get bedwarsBridgeBuilding4 => '敵の島への橋を始める前に十分なブロックを持っていることを確認しましょう。';

  @override
  String get bedwarsMidGameCombatTitle => '中盤の戦闘戦術';

  @override
  String get bedwarsMidGameCombat1 => 'ノックバック棒を使って敵を橋や島から落としましょう。';

  @override
  String get bedwarsMidGameCombat2 => '敵拠点に近づく際に弓で遠距離からプレッシャーをかけましょう。';

  @override
  String get bedwarsMidGameCombat3 => 'ファイヤーボールで防衛を突破し、プレイヤーを奈落に落としましょう。';

  @override
  String get bedwarsMidGameCombat4 => '厳しい戦闘の前に必ず金のリンゴを食べましょう。';

  @override
  String get bedwarsAdvancedPvpTitle => '上級PvP戦闘';

  @override
  String get bedwarsAdvancedPvp1 => 'ヒット間に前進キーを離して再度押すWタップコンボをマスターしましょう。';

  @override
  String get bedwarsAdvancedPvp2 => '釣り竿を使って敵を引き寄せ、ダッシュをリセットしましょう。';

  @override
  String get bedwarsAdvancedPvp3 => '予測不能なパターンで横移動して当たりにくくしましょう。';

  @override
  String get bedwarsAdvancedPvp4 => '釣り竿の引き寄せと即座の剣攻撃を組み合わせて強力なコンボを決めましょう。';

  @override
  String get bedwarsSpeedBridgingTitle => 'スピードブリッジと高度な移動';

  @override
  String get bedwarsSpeedBridging1 => 'しゃがまずに前進しながらブロックを置く忍者ブリッジを学びましょう。';

  @override
  String get bedwarsSpeedBridging2 => '最速の直線ブリッジ速度のためにブリーズリーブリッジを練習しましょう。';

  @override
  String get bedwarsSpeedBridging3 => '奈落への落下を防ぐためにブロッククラッチを使いましょう。';

  @override
  String get bedwarsSpeedBridging4 => 'ラッシュ中に素早くギャップを越えるためにジャンプブリッジをマスターしましょう。';

  @override
  String get bedwarsRushStrategiesTitle => 'ラッシュ戦略とタイミング';

  @override
  String get bedwarsRushStrategies1 => '最初の30秒以内に最も近い敵拠点にラッシュして早期の優位を得ましょう。';

  @override
  String get bedwarsRushStrategies2 => '防衛された拠点を素早く破壊するためにTNTとツルハシを購入しましょう。';

  @override
  String get bedwarsRushStrategies3 => '敵が資源収集のために拠点を離れるタイミングでラッシュしましょう。';

  @override
  String get bedwarsRushStrategies4 => '防衛の厚いベッドへの奇襲に透明化ポーションを使いましょう。';

  @override
  String get bedwarsEndgameTitle => '終盤の戦術と資源の優先順位';

  @override
  String get bedwarsEndgame1 => '素早い脱出と奇襲のためにエンダーパールを備蓄しましょう。';

  @override
  String get bedwarsEndgame2 => '最終戦に向けてダイヤモンド防具と鋭さアップグレードを優先しましょう。';

  @override
  String get bedwarsEndgame3 => '残りのチームから資源を奪うために中央マップのジェネレーターを制圧しましょう。';

  @override
  String get bedwarsEndgame4 => 'クラッチの瞬間に備えて緊急用ブロックと金のリンゴを常備しましょう。';

  @override
  String get bedwarsCounterStrategiesTitle => '一般的な戦術への対策';

  @override
  String get bedwarsCounterStrategies1 => '橋ラッシュには奈落トラップの設置や遠距離からの弓で対抗しましょう。';

  @override
  String get bedwarsCounterStrategies2 => 'TNT攻撃には防爆ガラスと黒曜石の層で対抗しましょう。';

  @override
  String get bedwarsCounterStrategies3 => '透明化プレイヤーには防具のパーティクルや足音に注意しましょう。';

  @override
  String get bedwarsCounterStrategies4 => 'ファイヤーボール連射には水バケツで消火しノックバックを防ぎましょう。';

  @override
  String get aboutTitle => '鉱石・構造物ファインダーについて';

  @override
  String get aboutWhatTitle => '🎯 このアプリの機能';

  @override
  String get aboutDescTitle => '高度なMinecraft鉱石・構造物発見ツール';

  @override
  String get aboutDescBody =>
      'ワールドシードと検索座標を入力して、ダイヤモンド、金、ネザライト、村、要塞などの正確な位置を発見しましょう。';

  @override
  String get aboutResourcesTitle => '⛏️ 対応する資源';

  @override
  String get aboutStructuresTitle => '🏘️ 対応する構造物';

  @override
  String get aboutHowItWorksTitle => '🔍 使い方';

  @override
  String get aboutFeaturesTitle => '✨ 主な機能';

  @override
  String get aboutSupportTitle => '☕ 開発を支援';

  @override
  String get aboutResourceDiamond => 'ダイヤモンド';

  @override
  String get aboutResourceGold => '金';

  @override
  String get aboutResourceNetherite => 'ネザライト';

  @override
  String get aboutResourceIron => '鉄';

  @override
  String get aboutResourceRedstone => 'レッドストーン';

  @override
  String get aboutResourceCoal => '石炭';

  @override
  String get aboutResourceLapis => 'ラピスラズリ';

  @override
  String get aboutStructureVillages => '村 🏘️';

  @override
  String get aboutStructureStrongholds => '要塞 🏰';

  @override
  String get aboutStructureDungeons => 'ダンジョン 🕳️';

  @override
  String get aboutStructureMineshafts => '廃坑 ⛏️';

  @override
  String get aboutStructureDesertTemples => '砂漠の寺院 🏜️';

  @override
  String get aboutStructureJungleTemples => 'ジャングルの寺院 🌿';

  @override
  String get aboutStructureOceanMonuments => '海底神殿 🌊';

  @override
  String get aboutStructureWoodlandMansions => '森の洋館 🏚️';

  @override
  String get aboutStructurePillagerOutposts => 'ピリジャーの前哨基地 ⚔️';

  @override
  String get aboutStructureRuinedPortals => '荒廃したポータル 🌀';

  @override
  String get aboutStep1 => '検索タブでワールドシードを入力';

  @override
  String get aboutStep2 => '検索中心の座標を設定（X、Y、Z）';

  @override
  String get aboutStep3 => '検索半径を選択';

  @override
  String get aboutStep4 => '検索する鉱石と構造物を選択';

  @override
  String get aboutStep5 => '「検索」をタップして近くの資源を発見';

  @override
  String get aboutStep6 => '正確な座標で結果を確認';

  @override
  String get aboutFeature1 => '最近のシード履歴 — 直近5つのシードにすぐアクセス';

  @override
  String get aboutFeature2 => 'パラメータ自動保存 — 検索設定を失いません';

  @override
  String get aboutFeature3 => '確率付き結果 — 最も可能性の高い場所を発見';

  @override
  String get aboutFeature4 => 'クロスプラットフォーム — Web、モバイル、デスクトップ対応';

  @override
  String get aboutFeature5 => 'ダーク/ライトテーマ — お好みの外観を選択';

  @override
  String get aboutBuyMeCoffee => 'コーヒーをおごる';

  @override
  String get aboutSupportBody =>
      'このアプリを無料で改善し続けるためにご支援ください！あなたのサポートが新機能と継続的な開発を可能にします。';

  @override
  String get aboutSupportButton => '開発を支援する';

  @override
  String get aboutFooterTip => '最近のシードを使ってワールド間を素早く切り替えましょう！';

  @override
  String get aboutGotIt => '了解！';

  @override
  String get releaseNotesHeader => 'リリースノート — v1.0.51';

  @override
  String get releaseNotesBedwarsSection => '🎮 ベッドウォーズ戦略ガイド — 新機能！';

  @override
  String get releaseNotesBedwarsGuideTitle => '完全版ベッドウォーズガイド';

  @override
  String get releaseNotesBedwarsGuideBody =>
      'ベッドウォーズの詳細な戦略を網羅した専用タブ。序盤のラッシュ、中盤の防衛、終盤の戦術をカバーし、すべての試合で勝利を目指しましょう。';

  @override
  String get releaseNotesResourceStrategiesTitle => '資源とショップの戦略';

  @override
  String get releaseNotesResourceStrategiesBody =>
      '資源の優先順位、各段階での最適なショップ購入、2人・3人・4人モードでのチーム連携のヒントを詳しく解説。';

  @override
  String get releaseNotesDefenseAttackTitle => '防衛と攻撃パターン';

  @override
  String get releaseNotesDefenseAttackBody =>
      'ベッド防衛のレイアウト、橋ラッシュテクニック、ファイヤーボール戦略、一般的な敵の戦術への対策を学びましょう。';

  @override
  String get releaseNotesUiSection => '🎨 モダンゲーマーUIの刷新';

  @override
  String get releaseNotesNeonTitle => 'ネオンゲーマー美学';

  @override
  String get releaseNotesNeonBody =>
      'ネオン・オン・ダークのカラーパレットで完全にビジュアルを再設計。鮮やかなグリーン、シアン、パープルのアクセントと微妙なグロー効果でモダンなゲーミング感を演出。';

  @override
  String get releaseNotesLightModeTitle => '改善されたライトモード';

  @override
  String get releaseNotesLightModeBody =>
      'より暗いアクセントバリアントを持つ完全に読みやすいライトテーマ。すべてのテキスト要素がライトとダークの両方の背景でコントラスト要件を満たします。';

  @override
  String get releaseNotesCardsTitle => '再設計されたカードとボタン';

  @override
  String get releaseNotesCardsBody =>
      'ネオンボーダーアクセントのフラットカード、グローシャドウ付きグラデーションアクションボタン、ネオンインジケーター付きのクリーンなタブバーが旧マテリアルグリーンテーマに代わります。';

  @override
  String get releaseNotesAlgorithmSection => '⛏️ 鉱石発見アルゴリズムの改善';

  @override
  String get releaseNotesNoiseTitle => '強化されたノイズ生成';

  @override
  String get releaseNotesNoiseBody =>
      '実際のゲーム内ワールド生成パターンにより正確に一致する、改善されたパーリンノイズ実装による鉱石確率計算。';

  @override
  String get releaseNotesBiomeTitle => '改善されたバイオーム認識';

  @override
  String get releaseNotesBiomeBody =>
      'バイオーム検出と鉱石分布モデリングの精度向上。荒野の金、深層のダイヤモンド、ネザーのネザライトがより正確に予測されます。';

  @override
  String get releaseNotesPerformanceTitle => '最適化された検索パフォーマンス';

  @override
  String get releaseNotesPerformanceBody =>
      '改善されたチャンクスキャンによる高速な検索実行。包括的ネザライト検索と大半径クエリがより効率的に完了します。';

  @override
  String get releaseNotesHighlightsSection => '🎯 ハイライト';

  @override
  String get releaseNotesHighlight1 => 'ベッドウォーズガイド: 序盤/中盤/終盤の戦術を網羅した完全戦略ガイド';

  @override
  String get releaseNotesHighlight2 => 'ゲーマーUI: ネオンアクセント、グロー効果、モダンダークテーマ';

  @override
  String get releaseNotesHighlight3 => 'ライトモード修正: すべてのテキストがライト背景で読みやすく';

  @override
  String get releaseNotesHighlight4 => '鉱石発見の改善: すべての鉱石タイプでより正確な予測';

  @override
  String get releaseNotesHighlight5 => '高速検索: 最適化されたアルゴリズムでより速い結果';

  @override
  String get releaseNotesHighlight6 => '5タブレイアウト: 検索、結果、ガイド、ベッドウォーズ、更新情報';

  @override
  String get releaseNotesHighlight7 =>
      'エディション＆バージョン: Java/Bedrockエディションとレガシー/モダンバージョン対応';

  @override
  String get releaseNotesTechnicalSection => '🔧 技術的な改善';

  @override
  String get releaseNotesTechnical1 => '適応型ライト/ダークカラーヘルパーを備えた集中テーマシステム';

  @override
  String get releaseNotesTechnical2 =>
      '再利用可能なGamerCardとGamerSectionHeaderコンポーネント';

  @override
  String get releaseNotesTechnical3 => '鉱石生成モデリングのための改善されたパーリンノイズ';

  @override
  String get releaseNotesTechnical4 => '改善されたチャンクレベルの確率計算';

  @override
  String get releaseNotesTechnical5 => 'スムーズなスクロールのためのウィジェット再構築の削減';

  @override
  String get releaseNotesTechnical6 =>
      'すべての鉱石計算でエディション対応RNGを実現するGameRandomストラテジーパターン';

  @override
  String get releaseNotesPreviousSection => '📋 過去の更新';

  @override
  String get releaseNotesV1042Title => 'v1.0.42 — ラピスラズリ + UI';

  @override
  String get releaseNotesV1042Body =>
      'ラピスラズリ鉱石の発見機能を追加。全7種の主要鉱石に対応。4タブナビゲーションレイアウトを強化。';

  @override
  String get releaseNotesV1041Title => 'v1.0.41 — 最近のシード履歴';

  @override
  String get releaseNotesV1041Body => '直近5つのシードにすぐアクセスできる自動シード履歴。';

  @override
  String get releaseNotesV1036Title => 'v1.0.36 — 完全な検索メモリ';

  @override
  String get releaseNotesV1036Body => '包括的な検索パラメータの永続化。';

  @override
  String get releaseNotesV1027Title => 'v1.0.27 — ビジュアル改善';

  @override
  String get releaseNotesV1027Body => 'スプラッシュスクリーンとアイコンを更新。';

  @override
  String get releaseNotesV1022Title => 'v1.0.22 — 拡張鉱石発見';

  @override
  String get releaseNotesV1022Body => '鉄、レッドストーン、石炭、ラピスラズリを追加。';

  @override
  String get releaseNotesV1015Title => 'v1.0.15 — 構造物発見';

  @override
  String get releaseNotesV1015Body => '村、要塞、ダンジョン、寺院など。';

  @override
  String get releaseNotesV1010Title => 'v1.0.10 — 基盤リリース';

  @override
  String get releaseNotesV1010Body => 'ダイヤモンド、金、ネザライトの基本的な発見機能。';

  @override
  String get releaseNotesTimelineSection => '🏆 バージョンタイムライン';

  @override
  String get releaseNotesTimelineCurrent => '現在';

  @override
  String get releaseNotesTimelinePrevious => '前回';

  @override
  String get releaseNotesTimelineEarlier => '以前';

  @override
  String get releaseNotesTimelineBedwarsUi => 'ベッドウォーズ + UI';

  @override
  String get releaseNotesTimelineLapisUi => 'ラピス + UI';

  @override
  String get releaseNotesTimelineRecentSeeds => '最近のシード';

  @override
  String get releaseNotesTimelineSearchMemory => '検索メモリ';

  @override
  String get releaseNotesTimelineVisualUpdates => 'ビジュアル更新';

  @override
  String get releaseNotesTimelineExtendedOres => '拡張鉱石';

  @override
  String get releaseNotesTimelineStructures => '構造物';

  @override
  String get releaseNotesTimelineCoreFeatures => 'コア機能';

  @override
  String get releaseNotesFooter =>
      '新機能: エディション＆バージョン選択、ベッドウォーズガイド、ゲーマーUI、改善された鉱石発見！';

  @override
  String get dialogReleaseNotesHeader => 'リリースノート - バージョン 1.0.41';

  @override
  String get dialogRecentSeedsSection => '🌱 最近のシード履歴 - 新機能！';

  @override
  String get dialogQuickSeedAccessTitle => 'クイックシードアクセス';

  @override
  String get dialogQuickSeedAccessBody =>
      'お気に入りのワールドシードを見失うことはもうありません！アプリが最後に検索した5つのシードを自動的に保存し、シード入力フィールドの下にクリック可能なオプションとして表示します。最近のシードをタップするだけで即座に再利用できます。';

  @override
  String get dialogSmartSeedTitle => 'スマートシード管理';

  @override
  String get dialogSmartSeedBody =>
      '最近のシードは自動的に管理されます。シードを再検索すると、リストの先頭に移動します。5シードの上限に達すると、最も古いシードが自動的に削除されます。改善されたモノスペースフォーマットですべてのシード数字が完全に表示されます。';

  @override
  String get dialogEnhancedUxTitle => '強化されたユーザー体験';

  @override
  String get dialogEnhancedUxBody =>
      '複数のシードをテストしたり、お気に入りのワールドに戻るプレイヤーに最適です。長いシード番号を手動で入力する必要はもうありません。クリックして検索するだけ！シードはアプリセッション間で保持されます。';

  @override
  String get dialogSearchMemorySection => '💾 完全な検索メモリ機能';

  @override
  String get dialogAutoSaveTitle => '自動パラメータ保存';

  @override
  String get dialogAutoSaveBody =>
      'アプリはワールドシード、X/Y/Z座標、検索半径を含むすべての検索パラメータを記憶します。入力時に自動的に保存され、アプリ再起動時に復元されます。';

  @override
  String get dialogSeamlessTitle => 'シームレスなワークフロー';

  @override
  String get dialogSeamlessBody =>
      '鉱石探索セッションを中断したところから正確に再開できます。座標の再入力や検索設定の調整は不要です。鉱石の発見に集中しましょう！';

  @override
  String get dialogEnhancedUxSection => '🎯 強化されたユーザー体験';

  @override
  String get dialogUxBullet1 => '最近のシード: 最後に検索した5つのワールドシードにすぐアクセス';

  @override
  String get dialogUxBullet2 => '時間節約: 検索パラメータを覚えて再入力する必要がなくなります';

  @override
  String get dialogUxBullet3 => '生産性向上: 鉱石発見に純粋に集中';

  @override
  String get dialogUxBullet4 => 'クロスプラットフォーム: すべてのサポートされたプラットフォームで一貫して動作';

  @override
  String get dialogUxBullet5 => 'スマートデフォルト: 新規ユーザーに適切なデフォルト値';

  @override
  String get dialogUxBullet6 => '読みやすさ向上: シード番号の視認性を高めるモノスペースフォント';

  @override
  String get dialogTechSection => '🔧 技術的な改善';

  @override
  String get dialogTechBullet1 => '最近のシードストレージ: 自動管理付きの永続的なシード履歴';

  @override
  String get dialogTechBullet2 => 'オフラインフォントサポート: インターネット接続なしでのパフォーマンス向上';

  @override
  String get dialogTechBullet3 => '包括的な永続化: すべてのテキスト入力フィールドが自動的に保存';

  @override
  String get dialogTechBullet4 =>
      '効率的なストレージ: 最適なパフォーマンスのためにプラットフォームネイティブストレージを使用';

  @override
  String get dialogTechBullet5 => '安定性の向上: より良いエラー処理とユーザー体験';

  @override
  String get dialogTechBullet6 => '完全なシード表示: シード番号が切り捨てなしで完全に表示';

  @override
  String get dialogPreviousSection => '📋 過去の更新';

  @override
  String get dialogV1036Title => 'バージョン 1.0.36 - 検索メモリ';

  @override
  String get dialogV1036Body => 'ワールドシード、座標、半径を含む完全な検索パラメータの永続化。';

  @override
  String get dialogV1027Title => 'バージョン 1.0.27 - マイナーアップデート';

  @override
  String get dialogV1027Body => 'より良い視覚的一貫性のためにスプラッシュスクリーンとアイコンを更新。';

  @override
  String get dialogV1022Title => 'バージョン 1.0.22 - 拡張鉱石発見';

  @override
  String get dialogV1022Body =>
      '⚪ 鉄鉱石 (Y -64〜256、Y 15 & Y 232でピーク)\n🔴 レッドストーン鉱石 (Y -64〜15、Y -64〜-59で90%)\n⚫ 石炭鉱石 (Y 0〜256、Y 96でピーク)\n🔵 ラピスラズリ (Y -64〜64、Y 0-32で強化)\nコンパクトな鉱石選択と視覚的凡例を備えた強化されたUI';

  @override
  String get dialogPlayersSection => '🎯 すべてのプレイヤーに最適';

  @override
  String get dialogPlayerBullet1 => 'シード探検家: お気に入りのワールドシード間を素早く切り替え';

  @override
  String get dialogPlayerBullet2 => 'スピードランナー: 保存されたパラメータで重要な鉱石にすぐアクセス';

  @override
  String get dialogPlayerBullet3 => '建築家: ツール用の鉄、メカニズム用のレッドストーン';

  @override
  String get dialogPlayerBullet4 => '一般プレイヤー: 採掘セッションのシームレスな継続';

  @override
  String get dialogPlayerBullet5 => '新規プレイヤー: 永続的な設定で最適な採掘レベルを学習';

  @override
  String get dialogPlayerBullet6 => 'コンテンツクリエイター: 異なるワールドを紹介するための簡単なシード管理';

  @override
  String get dialogFooter => '新機能: 最近のシード履歴 + すべての検索パラメータが自動保存！';

  @override
  String get dialogGotIt => '了解！';

  @override
  String get releaseNotesEditionSection => '🎮 エディション＆バージョン選択 — 新機能！';

  @override
  String get releaseNotesEditionSelectorTitle => 'Java＆Bedrockエディション対応';

  @override
  String get releaseNotesEditionSelectorBody =>
      'JavaエディションとBedrockエディションを選択できます。各エディションに正しい乱数生成器を使用し、鉱石予測が実際のワールドと一致します。';

  @override
  String get releaseNotesVersionEraTitle => 'レガシー＆モダンバージョン';

  @override
  String get releaseNotesVersionEraBody =>
      'Pre-1.18（レガシー）のクラシックな均一鉱石分布と固定Y範囲、または1.18+（モダン）の三角分布と拡張ワールド深度-64〜320を切り替えられます。';

  @override
  String get releaseNotesBedrockRngTitle => 'Bedrock RNGエンジン';

  @override
  String get releaseNotesBedrockRngBody =>
      '専用のメルセンヌ・ツイスターRNGがBedrockエディションのC++エンジンを再現します。予測が近似値の場合、コンテキスト情報ボックスでお知らせします。';

  @override
  String get releaseNotesV1050Title => 'v1.0.50 — ベッドウォーズ + UI';

  @override
  String get releaseNotesV1050Body =>
      '完全版ベッドウォーズ戦略ガイド。ネオン美学と改善されたライトモードによるモダンなゲーマーUIリデザイン。';

  @override
  String get releaseNotesTimelineEditionVersion => 'エディション + 時代';
}
