#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdint.h>
#include <dlfcn.h>
#include <vector>

// 3D ve 2D koordinat yapıları
struct Vector3 { float x, y, z; };
struct Vector2 { float x, y; };
struct Matrix4x4 { float m[4][4]; };

struct ESPPlayer {
    Vector2 ekranPos;
    bool isDushman;
};
std::vector<ESPPlayer> canliOyuncuListesi;

// iOS kancalama motoru
extern "C" void MSHookFunction(void *symbol, void *replace, void **result);

// Orijinal fonksiyonu yedekleyeceğimiz işaretçi
void (*old_PlayerManager_Update)(void *instance);

// Oyunun her karesinde çalışacak olan bizim fonksiyonumuz
void new_PlayerManager_Update(void *instance) {
    if (instance != NULL) {
        canliOyuncuListesi.clear(); // Her karede eski çizim pozisyonlarını temizle

        // Unity/Mono list yapısı üzerinden oyuncu verilerini topluyoruz
        uintptr_t allPlayersList = *(uintptr_t*)((uintptr_t)instance + 0x10); // all_players ofseti
        uintptr_t localPlayer = *(uintptr_t*)((uintptr_t)instance + 0x60);    // local_player ofseti

        if (allPlayersList != 0) {
            int oyuncuSayisi = *(int*)(allPlayersList + 0x18); // Oyuncu sayısı
            uintptr_t itemsArray = *(uintptr_t*)(allPlayersList + 0x10); // Liste dizisi

            for (int i = 0; i < oyuncuSayisi; i++) {
                // 64-bit iOS sisteminde her oyuncu adresi 8 byte (0x8) atlayarak ilerler
                uintptr_t playerEntity = *(uintptr_t*)(itemsArray + 0x20 + (i * 0x8));
                if (playerEntity == 0 || playerEntity == localPlayer) continue;

                // Test için şimdilik geçici boş verilerle listeyi dolduruyoruz
                ESPPlayer dusman;
                dusman.ekranPos = {0, 0}; 
                dusman.isDushman = true;
                canliOyuncuListesi.push_back(dusman);
            }
        }
    }
    // Oyunun takılmadan devam etmesi için akışı orijinal fonksiyona geri veriyoruz
    old_PlayerManager_Update(instance);
}

// Oyun açılıp dylib dosyası belleğe yüklendiği an çalışan kurucu fonksiyon
__attribute__((constructor)) static void initialize_tweak() {
    // Oyunun canlı çalışan ana bellek taban adresini yakalıyoruz
    uintptr_t il2cppBase = (uintptr_t)dlopen(NULL, RTLD_NOW);
    
    if (il2cppBase != 0) {
        // dump-0.38.2.txt içinden bulacağımız PlayerManager::Update fonksiyonunun gerçek ofset adresi
        // Şimdilik test amaçlı buraya temsili bir adres bırakıyoruz, dump taraması sonrası güncelleyeceğiz
        uintptr_t targetRVA = il2cppBase + 0x3A0B4C0; 
        
        // Kancayı atıyoruz
        MSHookFunction((void*)targetRVA, (void*)new_PlayerManager_Update, (void**)&old_PlayerManager_Update);
    }
}
