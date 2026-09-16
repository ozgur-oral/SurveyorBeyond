# Surveyor Beyond

Haritacılık ve ölçme mesleğini merkezine alan **mobil öncelikli** Godot 4 RPG + simülasyon oyunu.

## M0 — İlk Ölçüm

İlk oynanabilir prototipte oyuncu köylü NPC'den **Sınır Meselesi** görevini alır, dört sınır köşesini ölçer, poligonun alan/çevre hesabını tamamlar ve işi teslim ederek 250 para + 100 XP kazanır.

## Mobil Kontroller

Mobil oyun ana hedeftir. Temel oynanış klavye gerektirmeyecek şekilde tasarlanır:

- Sol alt: analog sanal joystick — karakter hareketi.
- Sağ alt: bağlama duyarlı dokunmatik eylem düğmesi.
- Düğme yakındaki duruma göre `KONUŞ`, `ÖLÇ`, `TESLİM` veya `ETKİLEŞ` işlevine dönüşür.
- Çoklu dokunma desteklenir; oyuncu joystick'i tutarken eylem düğmesine dokunabilir.
- Klavye kontrolleri yalnızca masaüstünde geliştirme/test kolaylığı için korunur.

## Mobil UX İlkeleri

- Ana eylemler ekran kenarlarında başparmak erişim alanında olacak.
- Küçük tıklama hedeflerinden kaçınılacak.
- Menü, görev seçimi, diyalog ve ekipman işlemleri dokunmatik kart/butonlarla yapılacak.
- Kritik işlemlerde görsel durum ve geri bildirim gösterilecek.
- Oyun 16:9 yatay mobil ekran temel alınarak geliştirilecek.

## Çalıştırma

1. Godot 4.x ile repository klasörünü açın.
2. `project.godot` dosyasını içe aktarın.
3. F6/F5 ile projeyi çalıştırın.

## Yol Haritası

- v0.0.1: Mobil hareket + temel dünya
- v0.0.2: Dokunmatik NPC/görev kabul/teslim sistemi
- v0.0.3: Ölçüm doğruluğu, kapanma hatası ve parsel hesabı
- v0.0.4: Dokunmatik ofis/proje akışı
- v0.0.5: XP, para ve karakter gelişimi

> Görseller şu an programcı grafikleri. Oynanış temeli oturduktan sonra modern atmosferik pixel-art dünyaya geçilecek.
