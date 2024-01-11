create table so_client_order_20231229 as
    select *
from CLIENT_ORDER
    where IS_ARCHIVED = 'Y'
and ROWNUM < 10;

update client_order
set is_archived = 'N'
where order_id in
      (14076898446, 14085945232, 13797684012, 14076897083, 14085886211, 13797683811, 14076897982, 13797684098,
       14076897516, 14076898907, 14076898189, 14076897024, 14076897989, 14085885535, 14076896522, 14076897920,
       14084863788, 14085879552, 14076898695, 14084781487, 14076898715, 14076898478, 14085992592, 14084669390,
       13797684316, 14084166466, 14085887651, 14076898007, 14076899229, 14084728608, 14076896817, 14076898368,
       14085882606, 14076897172, 14085883586, 14084399997, 14076898593, 14076899230, 14076897429, 14076899332,
       14076897871, 14076898565, 14076898619, 14085878227, 14085874546, 14076897204, 14076898905, 14076898952,
       14085879581, 14084364043, 14076897640, 14076898564, 14084763384, 14084294550, 14076900758, 14076904230,
       14085950636, 14076899109, 14076897199, 14076897695, 14076898819, 14076898906, 14076901940, 14085882608,
       13797684380, 14085887656, 14076900746, 14086103320, 14085946786, 14076897704, 14076896921, 14076897648,
       14076896868, 14076897093, 14076897644, 14085953390, 14076898399, 14076898631, 14085946848, 14084322646,
       14084611434, 14084604652, 14076898408, 14076897838, 14085742486, 14076898568, 13797684039, 14084322706,
       14084120347, 14076897667, 14084318984, 14076897641, 14085948993, 14076901796, 14084309975, 14085944805,
       14084363992, 13797683833, 14076897092, 14076896830, 14085950640, 14085953394, 14084687962, 14085954436,
       14076896900, 14076897099, 14085884062, 14076899505, 14085947696, 14076897087, 14085950135, 14085874981,
       14084120250, 14076898667, 14086152467, 14084350080, 14076899475, 14076899503, 14085875609, 14085877000,
       13797683856, 14084164682, 14076899255, 14085884586, 14085884061, 14084719561, 14086107605, 14085884581,
       14076898452, 14084863785, 14076899603, 14076898942, 14084852936, 14085875737, 14085954431, 14076898771,
       13797683797, 14084350043, 14084120340, 13797683827, 14076898053, 14084728611, 14076898454, 14076899291,
       14076898947, 14086118693, 14076898712, 14076900720, 14076897530, 14076897708, 14085876452, 14085617372,
       14076896822, 14084645715, 14085953627, 14086114245, 14096619335, 14076898587, 14076895338, 14086118695,
       14076897090, 14076897250, 14085882174, 14076898588, 14085882158, 14084164681, 14086107976, 14084638957,
       14085888461, 14076897424, 14076898950, 14076896799, 14076897752, 14084322716, 14086152262, 14085883554,
       14085888147, 14085882930, 14076898876, 14084454978, 14076897570, 14084599198, 13797684331, 14076898439,
       14076898162, 14076899149, 14084164679, 13797684219, 14085954954, 14076898650, 14085003459, 14076896831,
       14076897542, 14084611441, 14086110855, 14076897485, 14084763380, 14085876482, 14076897874, 14086114246,
       14086151506, 13797683982, 14076898974, 14085877054, 14084294551, 14085003460, 14076895334, 14084604650,
       14076898904, 14076896941, 14084131809, 14084992604, 14085884574, 14076897531, 14084303298, 14084526634,
       14085954958, 14076900772, 14076899104, 14085950132, 14076897431, 13797684310, 14085950556, 14076897962,
       14084166463, 14084821147, 14096618867, 14076899504, 14084120350, 14076897959, 14076898463, 13797683900,
       14076897473, 14084138025, 14085954150, 14076898366, 14076899262, 14085882198, 14076897157, 13797684202,
       14085946641, 13797683799, 14076897833, 14085888672, 14084363991, 14076897095, 13797684013, 14076897960,
       14076896780, 14085874565, 14085886186, 13797683828, 13797684358, 14076898955, 14076897706, 14076897919,
       14076900728, 14085887654, 14076898672, 14085876758, 14084510982, 14076898422, 14076897866, 14076895341,
       14084947145, 14085617354, 13797684038, 14085949830, 14076897081, 14085945547, 14076898008, 14076897006,
       14076899195, 14085950141, 14085946534, 14084326886, 14085883590, 14076897844, 14085880126, 14076899108,
       14076899486, 14084905042, 14084322745, 14084719563, 14085884063, 14085888048, 14085954558, 14084821145,
       14085887120, 14076896722, 14085954657, 14076899467, 14084976034, 14084825833, 13797684166, 14084852937,
       14085945225, 14084825834, 14076900738, 14076897711, 14076898694, 14084905040, 14076896770, 14076897254,
       14076897223, 14076897461, 14084326887, 14076899571, 14076896769, 13797683768, 14076897855, 14085882423,
       14085885500, 14076898820, 14076899680, 13797684178, 14085947590, 13797684040, 14096619334, 14085742494,
       14076899363, 14076899407, 14076898714, 14086153529, 14076898696, 14085893835, 14084642553, 14076899679,
       14076896810, 14076897835, 14076898453, 14076897088, 14076899151, 14076897676, 14076897098, 14076897755,
       13797683800, 14085933167, 14085073017, 14076897872, 14085809266, 14084497189, 14076898390, 14076899258,
       14085883254, 13797684272, 14085879573, 14076896952, 14084134013, 13797684177, 14084738990, 14085883583,
       14084363993, 14076895337, 14085944800, 14076897769, 14085953620, 14085882255, 14085946789, 13797683801,
       14084120341, 14086152263, 14085953387, 14085881993, 13797683824, 14076897715, 14084336360, 14076896523,
       13797683977, 14076899300, 14076899107, 14085796867, 14084777626, 13797684204, 13797683902, 14076896901,
       14084635839, 14076897558, 14076897156, 14085874644, 14076897674, 14076898909, 14076899334, 14076897224,
       14076897675, 14076899597, 13797683798, 14085949702, 14076899472, 14085887899, 14084638955, 14076896961,
       14086153527, 14086118696, 14076899031, 14085884086, 14096619336, 13797683947, 14076898801, 14076899071,
       14086037873, 14084350027, 14085946581, 14076898713, 14085883152, 14076898706, 14076900757, 14076897988,
       13797684002, 13797684005, 14076897136, 14085875679, 14076897639, 14085901259, 14084863790, 14076898821,
       13797684021, 13797683840, 14086110853, 14085947110, 14076899140, 14085943524, 13797684309, 14076898855,
       13797684281, 14084661353, 14076896925, 14076899194, 14086153528, 14076897460, 14076897758, 14076897638,
       14085949701, 14076895340, 14086118698, 14085887929, 14084645717, 14085003458, 14085883270, 14085879744,
       14084770787, 14076897477, 14076898673, 14076898911, 14076898074, 14076897096, 14084218530, 14085954162,
       14084947146, 14076899256, 14084497188, 14076897359, 13797684105, 14076898563, 13797684327, 14076896524,
       14076899150, 14076900771, 14086107975, 14076900727, 14076899248, 14085878013, 14085711949, 14084401145,
       13797684368, 14085955034, 14076899406, 14085882310, 14076896771, 14084322757, 14076899105, 14076897457,
       14076897490, 14085881485, 14076898710, 14084579216, 14076897885, 14076899485, 14076897668, 13797684235,
       14076896942, 14085954601, 14076896572, 14085875706, 14085617368, 14076898006, 14085954648, 14085889452,
       14076899634, 14076897875, 14076896905, 13797683806, 13797684011, 14085940246, 14076899226, 14085946577,
       14076897846, 14076898401, 14085954942, 14076897672, 14085940251, 14076896963, 14085933177, 14076899502,
       14076898009, 14076899405, 14076898449, 14076899364, 14085879526, 14076898948, 14084120344, 14076897138,
       14086112992, 14076899781, 14085796864, 14085888867, 14085874665, 14076897097, 14076898477, 14076899152,
       14076898589, 14085949828, 14085881410, 14084781491, 14076899554, 14085881963, 14084645719, 14085946771,
       13797684244, 14076899138, 14076898015, 14084638959, 14076898973, 14085933171, 14085954580, 14084205177,
       14085954609, 14076898400, 14085954959, 14076897643, 13797683802, 14076899193, 14084309973, 13797683792,
       14085954434, 14084120360, 14076898450, 14076898562, 14076899333, 14084120328, 14084120357, 14076896528,
       14085943304, 14076899601, 14085946533, 14076898004, 13797684194, 14076897423, 14084120251, 13797684179,
       14085947592, 14076898671, 13797683901, 14076897091, 14084120339, 14076901793, 14076896815, 14076898012,
       14076899030, 14076899028, 14084781489, 14076897663, 14076898013, 14085884087, 14076899602, 14076899469,
       14076898462, 14076898574, 14076896874, 14076898966, 14084763386, 14084363990, 14085882605, 14084642558,
       14076897964, 14085882339, 14084318987, 14076897845, 14076898903, 14076899484, 14085945227, 14084604648,
       14084218527, 14085874749, 14076898708, 13797684107, 14085943490, 14076899259, 14085948986, 14084635835,
       14076897832, 14085881912, 13797684175, 14076897750, 14076898430, 14084992603, 14085796865, 13797683785,
       14085954606, 14076895335, 14084611442, 14076897128, 14076899228, 14085882461, 14076898461, 14085950642,
       14076901792, 14085954516, 14076896785, 14084131810, 14086152261, 14076897645, 14076897637, 14076896571,
       14076901794, 14076898910, 14076897005, 14085940243, 14085883557, 14085879669, 14086114247, 14076896765,
       14085949697, 14076896706, 14085885503, 14085883455, 14084309972, 14085946791, 14076897559, 14076898505,
       14084526636, 14076897127, 14076897945, 14076898595, 14076899257, 14076897834, 14076898644, 13797683895,
       14076900770, 14085879626, 14076898470, 13797684421, 14085954540, 14076898014, 14076899476, 14076897357,
       14085954563, 14076896816, 14076898804, 14076897646, 14085954655, 14076899231, 13797684085, 14084120362,
       14086110140, 13797683939, 14076898649, 14084510979, 14076897873, 14076898476, 14076899386, 14085939309,
       14076898878, 14076897022, 14085887649, 14076898697, 14084120327, 14085949834, 14084642562, 14076896824,
       14076899362, 14076896829, 13797684003, 14085883268, 13797683826, 14076898456, 14096618866, 14084992602,
       14084758005, 14085945494, 14076897986, 14076897458, 14085950077, 14076896823, 14076897358, 14086152264,
       14084322637, 14076898124, 14076897990, 14084218529, 14085878873, 14084635837, 13797684271, 14076896795,
       14084582058, 14085933321, 14076897965, 14085742484, 14084437501, 14076896889, 13797684348, 14076897094,
       14084138024, 14076899156, 14076898709, 14085882386, 14085889401, 14084947144, 14076897203, 14084166465,
       14076899600, 14084747969, 13797684106, 14076897673, 14076898073, 14084953874, 14076898392, 14084120329,
       14085946532, 14076899365, 13797684165, 14076899316, 14076898075, 14085876485, 14085875775, 14084825831,
       14076898806, 14084450072, 14085992595, 14076899137, 14076897085, 14076899473, 14076898342, 14076897513,
       14085887125, 14076897100, 14076900734, 14076897155, 14076898972, 14085948984, 14084821146, 14076900721,
       14085889420, 14085887096, 13797683837, 14076896943, 14085882178, 13797683764, 14085933178, 14085950142,
       14085885501, 14085875917, 14096618868, 14076897202, 14076897870, 14085946525, 14076900769, 14076898648,
       14076897020, 14084566049, 14085955105, 14076897857, 14085992596, 14076898005, 14076897089, 14076896781,
       14076898451, 14084770786, 14085944801, 14076897101, 14076896828, 14076899563, 14085875656, 14076898427,
       14086152710, 14085887930, 14076897459, 14076898391, 14084364042, 14085887526, 14076899265, 14076897102,
       14076897716, 14076899227, 14085882343, 14084131807, 14076899468, 14076897225, 14085898975, 14076898578,
       14076898908, 14084322742, 14085950139, 14076899635, 14078566628, 14076897765, 14076897512, 14076898455,
       14076898805, 14084294548, 14076899029, 14076899139, 14076896726, 14084138023, 14076897252, 14076897086,
       14084781485, 14076897007, 14076898818, 14084599196, 14086096062, 14076897211, 14084364039, 14085888189,
       14076898096, 14085882446, 14085881640, 14085947593, 13797684360, 14084660364, 14076897174, 14085875684,
       14076899281, 14085933327, 14085877673, 14086151504, 14086110138, 14085874476, 14076900748, 14076897642,
       14085888187, 14086152465, 14076899057, 14085883556, 13797684084, 14085887927, 14084905044, 14085946035,
       14076898705, 13797684001, 14085950125, 13797684167, 14076899415, 14076897227, 14084322653, 14085883285,
       14076898877, 14085955101, 14085946527, 14084120252, 14076897946, 14084979233, 14076897084, 14084770789,
       14076897856, 14085955109, 14076898707, 14076900726, 14085882089, 14076899099, 13797684083, 13797683857,
       14085878795, 14076899681, 14076900733, 14086110139, 14076897432, 14084497190, 13797683858, 14084719564,
       14085953625, 14084326883, 14076898716, 14076899261, 14084611440, 14085889023, 14085950209, 14076899260,
       14085887743, 14076900729, 13797684361, 13797683832, 14076898951, 14076897137, 14076897601, 14076897669,
       14085884910, 14076898347, 14076897734, 14086151505, 14076899266, 13797683815, 14084318989, 14084526635,
       14084781493, 14076896747, 14076899254, 14076898971, 14084728602, 13797683825, 14076896755, 14076896783,
       14084510981, 14086152466, 14085954161, 14076897947, 14076897082, 14076897876, 14076898693, 14085946592,
       14085882184, 14084350046, 14085878008, 14076897987, 14084131808, 14076897848, 14076897975, 14076898402,
       14076897877, 14076898807, 14076897859, 14085884083, 14085933396, 13797684431, 14076897499, 14086152260,
       14085883265, 14076897958, 14086110854, 14085955345, 14084852935, 14085950192, 14085877168, 14086107974,
       13797684145, 14076897158, 14076899312, 14076900773, 13797684203, 14076897751, 14076900736, 14076897868,
       14084599197, 14076896573, 14076899474, 14085879350, 13797683839, 14085879717, 14076897251)
  and is_archived = 'Y';


insert into client_order_today
select *
from client_order cl
where order_id in