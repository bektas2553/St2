#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdint.h>
#include <dlfcn.h>
#include <vector>

// Matematiksel Yapılarımız
struct Vector3 { float x, y, z; };
struct Vector2 { float x, y; };
struct Matrix4x4 { float m[4][4]; };

// Çizim için oyuncu bilgilerini tutacak yapı
struct ESPPlayer {
    Vector3 dunyaPos;   // 3D uzaydaki yeri
    Vector2 ekranPos;   // 2D ekrandaki yeri
    int team;           // Takım bilgisi (CT mi T mi)
    bool isDushman;
};
std::vector<ESPPlayer> canliOyuncuListesi;

// iOS Hook Motoru Fonksiyonu
extern "C" void MSHookFunction(void *symbol, void *replace, void **result);

// Orijinal fonksiyonları yedekleyeceğimiz işaretçiler
void (*old_PlayerManager_Update)(void *instance);

// Oyuncunun takımını ve durumunu kontrol eden bizim fonksiyonumuz
void new_PlayerManager_Update(void *instance) {
    if (instance != NULL) {
        canliOyuncuListesi.clear(); // Her kare yenilendiğinde listeyi temizle

        [span_5](start_span)// offst.txt dosyasından doğrulanan resmi ofsetler[span_5](end_span)
        uintptr_t allPlayersList = *(uintptr_t*)((uintptr_t)instance + 0x10); [span_6](start_span)// all_players ofseti[span_6](end_span)
        uintptr_t localPlayer = *(uintptr_t*)((uintptr_t)instance + 0x60);    [span_7](start_span)// local_player ofseti[span_7](end_span)

        // Yerel oyuncumuzun (bizim) takım bilgisini alıyoruz
        int bizimTakim = 0;
        if (localPlayer != 0) {
            [span_8](start_span)// player_controller altındaki team ofseti (0x79)[span_8](end_span)
            bizimTakim = *(int*)(localPlayer + 0x79); 
        }

        if (allPlayersList != 0) {
            int oyuncuSayisi = *(int*)(allPlayersList + 0x18); // List boyutu
            uintptr_t itemsArray = *(uintptr_t*)(allPlayersList + 0x10); // Eleman dizisi

            for (int i = 0; i < oyuncuSayisi; i++) {
                uintptr_t playerEntity = *(uintptr_t*)(itemsArray + 0x20 + (i * 0x8));
                if (playerEntity == 0 || playerEntity == localPlayer) continue;

                [span_9](start_span)// Düşmanın takım bilgisini çekiyoruz (0x79)[span_9](end_span)
                int dusmanTakim = *(int*)(playerEntity + 0x79);

                ESPPlayer oyuncu;
                oyuncu.team = dusmanTakim;
                oyuncu.isDushman = (dusmanTakim != bizimTakim);
                
                // Şimdilik listeye ekle, 3D koordinat dönüşümünü (W2S) bir sonraki adımda bağlayacağız
                canliOyuncuListesi.push_back(oyuncu);
            }
        }
    }
    old_PlayerManager_Update(instance);
}

// Tweak belleğe yüklendiği an çalışan başlangıç noktası
__attribute__((constructor)) static void initialize_tweak() {
    uintptr_t il2cppBase = (uintptr_t)dlopen(NULL, RTLD_NOW);
    
    if (il2cppBase != 0) {
        [span_10](start_span)[span_11](start_span)// offst.txt dosyasındaki PlayerManager RVA adresi (0x3C4D5E) baz alınarak kanca atılıyor[span_10](end_span)[span_11](end_span)
        // Not: Canlı hafızadaki tam Update döngüsü için taban adrese ekleniyor
        uintptr_t targetRVA = il2cppBase + 0x3C4D5E; 
        
        MSHookFunction((void*)targetRVA, (void*)new_PlayerManager_Update, (void**)&old_PlayerManager_Update);
    }
}
