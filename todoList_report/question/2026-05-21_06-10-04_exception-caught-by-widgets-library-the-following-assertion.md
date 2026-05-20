# ======== Exception caught by widgets library ===================================

Session: `32f06577-e762-43c8-82ca-6f703e46a711`
Saved: 2026-05-20T21:10:04.241Z

## User

======== Exception caught by widgets library =======================================================
The following assertion was thrown while finalizing the widget tree:
'package:flutter/src/widgets/navigator.dart': Failed assertion: line 4081 pos 12: '!_debugLocked': is not true.


Either the assertion indicates an error in the framework itself, or we should provide substantially more information in this error message to help you determine and fix the underlying cause.
In either case, please report this assertion by filing a bug on GitHub:
  https://github.com/flutter/flutter/issues/new?template=02_bug.yml

When the exception was thrown, this was the stack: 
#2      NavigatorState.dispose (package:flutter/src/widgets/navigator.dart:4081:12)
#3      StatefulElement.unmount (package:flutter/src/widgets/framework.dart:6030:11)
#4      _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2117:13)
#5      _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#6      ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#7      _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#8      _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#9      ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#10     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#11     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#12     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#13     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#14     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#15     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#16     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#17     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#18     MultiChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7223:16)
#19     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#20     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#21     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#22     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#23     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#24     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#25     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#26     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#27     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#28     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#29     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#30     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#31     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#32     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#33     MultiChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7223:16)
#34     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#35     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#36     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#37     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#38     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#39     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#40     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#41     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#42     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#43     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#44     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#45     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#46     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#47     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#48     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#49     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#50     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#51     SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#52     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#53     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#54     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#55     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#56     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#57     SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#58     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#59     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#60     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#61     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#62     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#63     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#64     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#65     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#66     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#67     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#68     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#69     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#70     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#71     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#72     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#73     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#74     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#75     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#76     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#77     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#78     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#79     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#80     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#81     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#82     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#83     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#84     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#85     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#86     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#87     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#88     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#89     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#90     SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#91     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#92     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#93     ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#94     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#95     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#96     SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#97     _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#98     _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#99     SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#100    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#101    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#102    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#103    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#104    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#105    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#106    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#107    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#108    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#109    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#110    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#111    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#112    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#113    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#114    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#115    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#116    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#117    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#118    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#119    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#120    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#121    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#122    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#123    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#124    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#125    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#126    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#127    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#128    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#129    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#130    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#131    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#132    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#133    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#134    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#135    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#136    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#137    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#138    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#139    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#140    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#141    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#142    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#143    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#144    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#145    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#146    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#147    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#148    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#149    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#150    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#151    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#152    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#153    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#154    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#155    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#156    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#157    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#158    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#159    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#160    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#161    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#162    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#163    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#164    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#165    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#166    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#167    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#168    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#169    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#170    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#171    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#172    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#173    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#174    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#175    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#176    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#177    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#178    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#179    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#180    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#181    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#182    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#183    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#184    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#185    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#186    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#187    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#188    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#189    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#190    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#191    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#192    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#193    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#194    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#195    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#196    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#197    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#198    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#199    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#200    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#201    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#202    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#203    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#204    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#205    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#206    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#207    MultiChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7223:16)
#208    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#209    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#210    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#211    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#212    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#213    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#214    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#215    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#216    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#217    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#218    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#219    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#220    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#221    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#222    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#223    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#224    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#225    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#226    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#227    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#228    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#229    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#230    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#231    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#232    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#233    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#234    SingleChildRenderObjectElement.visitChildren (package:flutter/src/widgets/framework.dart:7101:14)
#235    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#236    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#237    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#238    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#239    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#240    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#241    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#242    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#243    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#244    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#245    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#246    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#247    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#248    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#249    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#250    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#251    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#252    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#253    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#254    _InactiveElements._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:2115:7)
#255    ComponentElement.visitChildren (package:flutter/src/widgets/framework.dart:5871:14)
#256    _InactiveElements._unmount (package:flutter/src/widgets/framework.dart:2113:13)
#257    ListIterable.forEach (dart:_internal/iterable.dart:49:13)
#258    _InactiveElements._unmountAll (package:flutter/src/widgets/framework.dart:2126:25)
#259    BuildOwner.lockState (package:flutter/src/widgets/framework.dart:3020:15)
#260    BuildOwner.finalizeTree (package:flutter/src/widgets/framework.dart:3344:7)
#261    WidgetsBinding.drawFrame (package:flutter/src/widgets/binding.dart:1309:19)
#262    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#263    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1430:15)
#264    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1345:9)
#265    SchedulerBinding._handleDrawFrame (package:flutter/src/scheduler/binding.dart:1198:5)
#266    _invoke (dart:ui/hooks.dart:356:13)
#267    PlatformDispatcher._drawFrame (dart:ui/platform_dispatcher.dart:444:5)
#268    _drawFrame (dart:ui/hooks.dart:328:31)
(elided 2 frames from class _AssertionError)
====================================================================================================

## Assistant

This is a known Flutter framework assertion (`!_debugLocked`) thrown by `NavigatorState.dispose`. It means a Navigator is being **disposed while a navigation operation is still in flight** — usually triggered by rapid back-to-back `context.go` / `context.push` calls during a teardown, or by navigation that fires while a frame is already finalizing.

The stack trace doesn't tell us **which** of our `context.go` calls triggered it — to pin it down, I need to know what you did right before this error:

## Assistant

Got it — the actual culprit is **not** the original stack trace I saw, it's the delete-confirmation dialog in `conversation_history_screen.dart:164`. The dialog's `Navigator.of(context).pop(...)` is popping the wrong Navigator and emptying go_router's match list. Let me look.

## Assistant

**Found the bug.** Both `Navigator.of(context).pop(...)` calls in the dialog's buttons are using the **outer screen's context**, not the dialog's own context. Since the history screen now lives inside the `ShellRoute`, the screen's context's nearest Navigator is the **shell's nested Navigator** — so the pop dismantles the shell tab instead of the dialog. That empties go_router's match list and trips the cascade you saw.

Fix: use the dialog's `builder` context for the navigator lookup.

## Assistant

Let me check for the same pattern elsewhere in shell-tab screens (now that conversation_history is inside the shell, others might be at risk too).

## Assistant

Those other sites are safe — they're inside dialog body widgets that have their own root-navigator-rooted context (and `scenario_brief_screen` is a top-level route, not inside the shell). The history screen was unique because its AlertDialog's button closures captured the outer screen's context, which lives inside the shell.

## Assistant

Clean. Commit + log.

## Assistant

The actual fix file didn't make it into the commit. Let me check status.

## Assistant

Turns out an auto-commit (`d1b4d8e`) landed the fix already before my git add; my commit `74fe0a2` only adds the story log. Both are in history.

## Assistant

Both pieces are in: the fix in `d1b4d8e`, the story log in `74fe0a2`.

**Root cause** (now visible from the second stack trace you pasted): the `Cancel` / `Delete` buttons in the delete-confirmation dialog were calling `Navigator.of(context).pop(...)` using the **outer screen's context** — captured by the closure. After [`f2b8628`](#) promoted `conversation_history_screen` to a shell tab, that outer context's nearest Navigator is the **ShellRoute's nested Navigator**, not the root.

Sequence:
1. Tap **Cancel** or **Delete** → `Navigator.of(outer-context).pop(...)` resolves to the shell's nested Navigator.
2. That Navigator only had `/conversations/history` on its stack → pop empties it.
3. `GoRouterDelegate._handlePopPageWithRouteMatch` sees the match list go empty → trips `assert(currentConfiguration.isNotEmpty)`.
4. While unwinding, the shell subtree is torn down → the `NavigatorState.dispose` `_debugLocked` assertion fires from `finalizeTree`. That's the second, downstream stack you originally pasted.

**The fix**: name the dialog's `builder` parameter `dialogContext` and use it for `Navigator.of(...)` inside the actions. `dialogContext` resolves to the **root** Navigator where `showDialog` put the dialog, so the pop dismisses just the dialog.

**General rule worth remembering** going forward: any dialog inside a shell-tab screen must use the dialog's own builder context for navigator operations. Checked `change_password_dialog`, `edit_profile_dialog`, and `scenario_brief_screen` — those are safe (their pops use inner dialog-body contexts, or the screen is outside the shell).

Hot-restart and the delete-confirm flow should work cleanly now.
