# Asteroid Escape (Asteroidden Kaçış)

Intel 8086 mimarisi üzerinde, x86 Assembly dili kullanılarak geliştirilmiş gerçek zamanlı bir kaçış oyunudur. Proje, düşük seviyeli donanım programlama prensiplerini ve doğrudan sistem kaynaklarını yönetmeyi amaçlar.

## Proje Özellikleri
- **Grafik Modu:** 320x200 çözünürlüğünde 256 renk destekli `VGA Mode 13h` kullanımı.
- **Gerçek Zamanlı Mekanikler:** Sistem saati (INT 1Ah) tabanlı oyun döngüsü ve hareket yönetimi.
- **Çarpışma Algılama:** Nesneler arası AABB (Axis-Aligned Bounding Box) algoritması.
- **Rastgelelik:** Sistem zamanlayıcısından alınan seed değeri ile dinamik asteroid konumlandırma.

## Kullanılan Teknolojiler
- **Dil:** Assembly (x86)
- **Derleyici:** NASM (Netwide Assembler)
- **Emülatör:** DOSBox

## Kurulum ve Çalıştırma
Projeyi çalıştırmak için sisteminizde **DOSBox** ve **nasm.exe** bulunmalıdır.
