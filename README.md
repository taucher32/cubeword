# Cubeword

Cubeword, küpleri döndürüp kelime oluşturduğunuz Türkçe bir kelime bulmaca oyunudur.

## Oyun Tahtası

- Tahta **2 × 6** hücreden oluşur.
- **Üst satır (spawn satırı):** Yeni küplerin göründüğü yer. Dokunarak döndürülür.
- **Alt satır (kelime satırı):** Küplerin indirildiği ve kelimenin oluşturulduğu yer.
- Her sütunda en fazla 1 küp bulunabilir.

## Oyun Akışı

1. Üst satırdaki küplere dokunarak döndür; istediğin harfi öne getir.
2. Alt satırdaki boş hücreye dokunarak küpü indir.
3. **Kelime Gönder** düğmesine bas.
4. Geçerli Türkçe kelime → `uzunluk × 10` puan kazanırsın.
5. Hedef kelimeyi bulduysan tur biter, yeni tur başlar.

## Puanlama

| Kelime uzunluğu | Puan |
|---|---|
| 2 harf | 20 |
| 3 harf | 30 |
| 4 harf | 40 |
| 5 harf | 50 |
| 6 harf | 60 |

## Düğmeler

- **Kelime Gönder:** Kelime satırını sözlükle karşılaştırır ve puanı verir.
- **Satırı Temizle:** Kelime satırını boşaltır.
- **Yeni Tur:** Hedef kelime bulunduktan sonra yeni tura geçer.
- **Yenile (↺):** Oyunu sıfırlar.

## Sözlük

Kelimeler `assets/words_tr.txt` dosyasından yüklenir (~500 Türkçe kelime, 2–6 harf).

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
```
