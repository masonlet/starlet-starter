#ifndef NDEBUG
	#define _CRTDBG_MAP_ALLOC
	#include <crtdbg.h>
	#include <cstdlib>
#endif

#include <starlet-engine/engine.hpp>

int main() {
#ifndef NDEBUG
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
	//_CrtSetBreakAlloc();
#endif
	
	Starlet::Engine::Engine engine;
	engine.setAssetPaths(std::string(ASSET_DIR));

	if (!engine.initialize(1920, 1080, "Starlet Project")) 
		return -1;

	if (!engine.loadScene("EmptyScene"))          
		return -1;
	
	engine.run();
}
