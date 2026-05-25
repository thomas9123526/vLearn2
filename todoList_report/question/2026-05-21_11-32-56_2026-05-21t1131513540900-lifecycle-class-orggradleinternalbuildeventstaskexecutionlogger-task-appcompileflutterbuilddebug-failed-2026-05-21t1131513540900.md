# 2026-05-21T11:31:51.354+0900 [LIFECYCLE] [class org.gradle.internal.buildevents.

Session: `c8b9bc59-8e0b-457d-a3e0-6557fcbf5b50`
Saved: 2026-05-21T02:32:56.508Z

## User

2026-05-21T11:31:51.354+0900 [LIFECYCLE] [class org.gradle.internal.buildevents.TaskExecutionLogger] > Task :app:compileFlutterBuildDebug FAILED
2026-05-21T11:31:51.354+0900 [DEBUG] [org.gradle.api.internal.tasks.execution.ResolveTaskExecutionModeExecuter] Putting task artifact state for task ':app:compileFlutterBuildDebug' into context took 0.0 secs.
2026-05-21T11:31:51.355+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Identifying work' completed
2026-05-21T11:31:51.356+0900 [DEBUG] [org.gradle.internal.execution.steps.AbstractCaptureStateBeforeExecutionStep] Implementation for task ':app:compileFlutterBuildDebug': com.flutter.gradle.tasks.FlutterTask_Decorated@9d044dca61a0cb66d9c7caad8effcb1b
2026-05-21T11:31:51.356+0900 [DEBUG] [org.gradle.internal.execution.steps.AbstractCaptureStateBeforeExecutionStep] Additional implementations for task ':app:compileFlutterBuildDebug': [com.flutter.gradle.tasks.FlutterTask_Decorated@9d044dca61a0cb66d9c7caad8effcb1b]
2026-05-21T11:31:51.356+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Snapshot inputs and outputs before executing task ':app:compileFlutterBuildDebug'' completed
2026-05-21T11:31:51.357+0900 [INFO] [org.gradle.internal.execution.steps.AbstractResolveCachingStateStep] Caching disabled for task ':app:compileFlutterBuildDebug' because:
  Build cache is disabled
  Caching has not been enabled for the task
2026-05-21T11:31:51.357+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Snapshot task inputs for :app:compileFlutterBuildDebug' completed
2026-05-21T11:31:51.357+0900 [DEBUG] [org.gradle.internal.execution.steps.SkipUpToDateStep] Determining if task ':app:compileFlutterBuildDebug' is up-to-date
2026-05-21T11:31:51.357+0900 [INFO] [org.gradle.internal.execution.steps.SkipUpToDateStep] Task ':app:compileFlutterBuildDebug' is not up-to-date because:
  Task has failed previously.
2026-05-21T11:31:51.357+0900 [DEBUG] [org.gradle.internal.vfs.impl.AbstractVirtualFileSystem] Invalidating VFS paths: [C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug\flutter_build.d, C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug]
2026-05-21T11:31:51.358+0900 [DEBUG] [org.gradle.internal.execution.steps.PreCreateOutputParentsStep] Ensuring parent directory exists for property dependenciesFiles$1 at C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug\flutter_build.d
2026-05-21T11:31:51.358+0900 [DEBUG] [org.gradle.internal.execution.steps.PreCreateOutputParentsStep] Ensuring directory exists for property outputDirectory at C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug
2026-05-21T11:31:51.358+0900 [DEBUG] [org.gradle.api.internal.tasks.execution.TaskExecution] Executing actions for task ':app:compileFlutterBuildDebug'.
2026-05-21T11:31:51.359+0900 [INFO] [org.gradle.process.internal.DefaultExecHandle] Starting process 'command 'C:\flutter\bin\flutter.bat''. Working directory: C:\project\vLearn2\flutter_app Command: C:\flutter\bin\flutter.bat --quiet assemble --no-version-check --depfile C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug/flutter_build.d --output C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug -dTargetFile=lib/main.dart -dTargetPlatform=android -dBuildMode=debug -dTrackWidgetCreation=true -dFlavor= -dAndroidArchs=android-arm android-arm64 android-x64 -dMinSdkVersion=24 debug_android_application
2026-05-21T11:31:51.359+0900 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Changing state to: STARTING
2026-05-21T11:31:51.359+0900 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Waiting until process started: command 'C:\flutter\bin\flutter.bat'.
2026-05-21T11:31:51.364+0900 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Changing state to: STARTED
2026-05-21T11:31:51.364+0900 [DEBUG] [org.gradle.process.internal.ExecHandleRunner] waiting until streams are handled...
2026-05-21T11:31:51.364+0900 [INFO] [org.gradle.process.internal.DefaultExecHandle] Successfully started process 'command 'C:\flutter\bin\flutter.bat''
2026-05-21T11:31:52.716+0900 [ERROR] [system.err] C:\project\vLearn2\flutter_app\.dart_tool\package_config.json does not exist.
2026-05-21T11:31:52.716+0900 [ERROR] [system.err] Did you run this command from the same directory as your pubspec.yaml file?
2026-05-21T11:31:52.717+0900 [ERROR] [system.err] C:\project\vLearn2\flutter_app\.dart_tool\package_config.json does not exist.
2026-05-21T11:31:52.717+0900 [ERROR] [system.err] Did you run this command from the same directory as your pubspec.yaml file?
2026-05-21T11:31:52.722+0900 [ERROR] [system.err] Target dart_build failed: Error: 
2026-05-21T11:31:52.722+0900 [ERROR] [system.err] Target gen_dart_plugin_registrant failed: Error: 
2026-05-21T11:31:52.807+0900 [ERROR] [system.err] 
2026-05-21T11:31:53.083+0900 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Changing state to: FAILED
2026-05-21T11:31:53.083+0900 [DEBUG] [org.gradle.process.internal.DefaultExecHandle] Process 'command 'C:\flutter\bin\flutter.bat'' finished with exit value 1 (state: FAILED)
2026-05-21T11:31:53.084+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Execute build for :app:compileFlutterBuildDebug' completed
2026-05-21T11:31:53.084+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Executing task ':app:compileFlutterBuildDebug'' completed
2026-05-21T11:31:53.084+0900 [DEBUG] [org.gradle.internal.vfs.impl.AbstractVirtualFileSystem] Invalidating VFS paths: [C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug\flutter_build.d, C:\project\vLearn2\flutter_app\build\app\intermediates\flutter\debug]
2026-05-21T11:31:53.085+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Snapshot outputs after executing task ':app:compileFlutterBuildDebug'' completed
2026-05-21T11:31:53.085+0900 [DEBUG] [org.gradle.api.internal.tasks.execution.ResolveTaskExecutionModeExecuter] Removed task artifact state for task ':app:compileFlutterBuildDebug' from context.
2026-05-21T11:31:53.085+0900 [DEBUG] [org.gradle.cache.internal.btree.BTreePersistentIndexedCache] Opening cache outputFiles.bin (C:\project\vLearn2\flutter_app\android\.gradle\buildOutputCleanup\outputFiles.bin)
2026-05-21T11:31:53.086+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Completing Build operation 'Task :app:compileFlutterBuildDebug'
2026-05-21T11:31:53.086+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Task :app:compileFlutterBuildDebug' completed
2026-05-21T11:31:53.086+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:compileFlutterBuildDebug completed, executed: true
2026-05-21T11:31:53.086+0900 [DEBUG] [org.gradle.launcher.daemon.server.SynchronizedDispatchConnection] thread 485: dispatching BuildEvent[event=org.gradle.internal.build.event.types.DefaultTaskFinishedProgressEvent@1f96787a]
2026-05-21T11:31:53.086+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:compileFlutterBuildDebug failed
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: released lock on state of project :app
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: released lock on task execution for :app
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:packJniLibsflutterBuildDebug completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:packJniLibsflutterBuildDebug completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:checkDebugAarMetadata completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:checkDebugAarMetadata completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: acquired lock on state of project :app
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: acquired lock on task execution for :app
2026-05-21T11:31:53.087+0900 [INFO] [org.gradle.execution.plan.DefaultPlanExecutor] Resolve mutations for :app:cleanMergeDebugAssets (Thread[#535,included builds,5,main]) started.
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 6: acquired lock on worker lease
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeDebugAssets completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeDebugAssets completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:copyFlutterAssetsDebug completed, executed: false
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Resolve mutations for task :app:cleanMergeDebugAssets' started
2026-05-21T11:31:53.087+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:copyFlutterAssetsDebug completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mapDebugSourceSetPaths completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mapDebugSourceSetPaths completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeDebugResources completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeDebugResources completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:processDebugMainManifest completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:processDebugMainManifest completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:outputDebugAppLinkSettings completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:outputDebugAppLinkSettings completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:processDebugManifest completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:processDebugManifest completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:processDebugManifestForPackage completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:processDebugManifestForPackage completed, executed: false
2026-05-21T11:31:53.088+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Completing Build operation 'Resolve mutations for task :app:cleanMergeDebugAssets'
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Resolve mutations for task :app:cleanMergeDebugAssets' completed
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:processDebugResources completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:processDebugResources completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:compileDebugKotlin completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:compileDebugKotlin completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:compileDebugJavaWithJavac completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:compileDebugJavaWithJavac completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:compressDebugAssets completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:compressDebugAssets completed, executed: false
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.089+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:desugarDebugFileDependencies completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:desugarDebugFileDependencies completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:dexBuilderDebug completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:dexBuilderDebug completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeDebugGlobalSynthetics completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeDebugGlobalSynthetics completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:processDebugJavaRes completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:processDebugJavaRes completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeDebugJavaResource completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeDebugJavaResource completed, executed: false
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.090+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:checkDebugDuplicateClasses completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:checkDebugDuplicateClasses completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeExtDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeExtDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeLibDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeLibDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeProjectDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeProjectDexDebug completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:configureCMakeDebug[arm64-v8a] completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:configureCMakeDebug[arm64-v8a] completed, executed: false
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.091+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:buildCMakeDebug[arm64-v8a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:buildCMakeDebug[arm64-v8a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:configureCMakeDebug[armeabi-v7a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:configureCMakeDebug[armeabi-v7a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:buildCMakeDebug[armeabi-v7a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:buildCMakeDebug[armeabi-v7a] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:configureCMakeDebug[x86_64] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:configureCMakeDebug[x86_64] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:buildCMakeDebug[x86_64] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:buildCMakeDebug[x86_64] completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:mergeDebugNativeLibs completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:mergeDebugNativeLibs completed, executed: false
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.092+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:stripDebugDebugSymbols completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:stripDebugDebugSymbols completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:validateSigningDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugAppMetadata
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugSigningConfigVersions
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:packageDebug completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:packageDebug completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:validateSigningDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugAppMetadata
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugSigningConfigVersions
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:createDebugApkListingFileRedirect completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:createDebugApkListingFileRedirect completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:validateSigningDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugAppMetadata
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugSigningConfigVersions
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node :app:assembleDebug completed, executed: false
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:validateSigningDebug
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugAppMetadata
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugSigningConfigVersions
2026-05-21T11:31:53.093+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 6: released lock on worker lease
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:cleanMergeDebugAssets completed, executed: true
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Node Resolve mutations for :app:cleanMergeDebugAssets finished executing
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: released lock on state of project :app
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: released lock on task execution for :app
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: acquired lock on state of project :app
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] included builds: acquired lock on task execution for :app
2026-05-21T11:31:53.094+0900 [INFO] [org.gradle.execution.plan.DefaultPlanExecutor] :app:cleanMergeDebugAssets (Thread[#535,included builds,5,main]) started.
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker: acquired lock on worker lease
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugShaders
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:generateDebugResValues
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:createDebugCompatibleScreenManifests
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:javaPreCompileDebug
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:mergeDebugJniLibFolders
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:validateSigningDebug
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugAppMetadata
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.execution.plan.DefaultFinalizedExecutionPlan] Cannot acquire project lock for node Resolve mutations for :app:writeDebugSigningConfigVersions
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker: released lock on worker lease
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Task :app:cleanMergeDebugAssets' started
2026-05-21T11:31:53.094+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 2: acquired lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.launcher.daemon.server.SynchronizedDispatchConnection] thread 485: dispatching BuildEvent[event=org.gradle.internal.build.event.types.DefaultTaskStartedProgressEvent@6d97ea98]
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 2: released lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Identifying work' started
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 7: acquired lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 7: released lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Completing Build operation 'Identifying work'
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 5: acquired lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 5: released lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.operations.DefaultBuildOperationRunner] Build operation 'Snapshot task inputs for :app:cleanMergeDebugAssets' started
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 4: acquired lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 4: released lock on worker lease
2026-05-21T11:31:53.095+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 3: acquired lock on worker lease
2026-05-21T11:31:53.096+0900 [DEBUG] [org.gradle.internal.resources.AbstractTrackedResourceLock] Execution worker Thread 3: released lock on worker lease
2026-05-21T11:31:53.096+0900 [DEBUG] [org.gradle.internal.reso

[Message truncated - exceeded 50,000 character limit]

## Assistant

The actual error is buried near the top of all that Gradle noise:

```
C:\project\vLearn2\flutter_app\.dart_tool\package_config.json does not exist.
Did you run this command from the same directory as your pubspec.yaml file?
Target dart_build failed
Target gen_dart_plugin_registrant failed
```

That file is generated by `flutter pub get`. It was either never created, deleted by a `flutter clean`, or wiped by something else. Without it Flutter can't resolve any package, so the Android build fails before it even tries to compile Dart.

## Fix

From the Flutter project root:

```
cd c:\project\vLearn2\flutter_app
flutter pub get
flutter run
```

That single `flutter pub get` recreates `.dart_tool/package_config.json` + `.dart_tool/version` + the `pubspec.lock` if missing.

If `flutter pub get` itself errors, run it with `-v` and check the output:

```
flutter pub get -v
```

## Common reasons it disappears

| Cause | Tell |
|---|---|
| Just ran `flutter clean` | `.dart_tool/` is gone entirely → `flutter pub get` |
| Switched Flutter SDK versions | `.dart_tool/` was created by another SDK and got invalidated → `flutter pub get` |
| `pubspec.yaml` edit + IDE didn't auto-fetch | IDE may rely on a save-action that didn't fire → `flutter pub get` |
| `pubspec.yaml` has an actual error (bad dep, version conflict) | `flutter pub get` will report it explicitly — fix and re-run |

## Sanity check after

```
dir .dart_tool\package_config.json     # should now exist
flutter doctor                          # confirm SDK is healthy
flutter run                             # rebuild
```

Once `flutter pub get` succeeds, the Gradle build will get past `:app:compileFlutterBuildDebug` cleanly.
