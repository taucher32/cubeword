# Room: RoomDatabase alt sınıflarının parametresiz kurucusunu koru.
#
# Room, veritabanı örneğini "<DatabaseSınıfı>_Impl" adlı üretilmiş sınıfı
# reflection ile bulup parametresiz kurucusuyla oluşturur. Room 2.2.5'in kendi
# proguard.txt'i yalnızca sınıfı koruyor, kurucuyu korumuyor:
#
#     -keep class * extends androidx.room.RoomDatabase
#
# R8 full mode'da sınıfı korumak kurucuyu korumaya yetmez; kullanılmayan kurucu
# budanır ve uygulama açılışta çöker:
#
#     RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
#         at androidx.work.WorkManagerInitializer
#         at androidx.startup.InitializationProvider.onCreate
#
# AGP 9'da R8 full mode zorunlu hale geldiği için (android.enableR8.fullMode
# kaldırıldı) bu kural şart oldu. Room 2.4+ kuralı düzeltilmiş şekilde kendi
# gönderiyor; buradaki Room 2.2.5, androidx.work 2.7.0 -> google_mobile_ads
# zincirinden geçişli olarak geliyor. O bağımlılıklar Room 2.4+'a çıktığında
# bu blok silinebilir.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
