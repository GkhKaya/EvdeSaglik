# Evde Sağlık - AI-Powered Health Application

## 📱 Uygulama Hakkında

**Evde Sağlık**, günümüzdeki hastane yoğunluk problemini azaltmak için geliştirilmiş, yapay zeka destekli bir sağlık uygulamasıdır. Kullanıcılara hastalıklarına doğal ve evde yapabilecekleri çözümler sunar, bu çözümleri kayıt altına almalarını sağlar ve her türlü sağlık sorununa kişiselleştirilmiş cevaplar verir.

## 🎯 Uygulama Amacı

Bu uygulama, hastane yoğunluğunu azaltmak ve kullanıcıların sağlık ihtiyaçlarını evde karşılayabilmelerini sağlamak amacıyla tasarlanmıştır. Yapay zeka teknolojisi kullanarak:

- **Doğal Çözümler**: Hastalıklar için evde uygulanabilir doğal tedavi yöntemleri
- **Kişiselleştirilmiş Öneriler**: Kullanıcı bilgilerine göre özelleştirilmiş sağlık tavsiyeleri
- **Kayıt Sistemi**: Uygulanan çözümlerin takibi ve geçmiş kayıtları
- **AI Asistan**: Sağlık sorularına anında ve doğru cevaplar

## 🏗️ Teknik Mimari

### **Mimari Desen**
- **MVVM (Model-View-ViewModel)**: Temiz kod ve test edilebilirlik için
- **Dependency Injection**: Modüler ve esnek yapı
- **Repository Pattern**: Veri erişim katmanının soyutlanması

### **Kullanılan Teknolojiler**

#### **Frontend**
- **SwiftUI**: Modern iOS UI framework
- **Combine**: Reactive programming ve data binding
- **Async/Await**: Modern Swift concurrency

#### **Backend & Veritabanı**
- **Firebase Authentication**: Kullanıcı kimlik doğrulama
- **Firestore**: NoSQL veritabanı
- **Firebase Analytics**: Kullanım analitikleri

#### **Yapay Zeka**
- **OpenRouter DeepSeek**: Ana AI modeli
- **Custom AI Response Parser**: AI yanıtlarının işlenmesi
- **Context-Aware Responses**: Kullanıcı bilgilerine göre kişiselleştirme

#### **UI/UX**
- **Responsive Design**: Farklı ekran boyutlarına uyum
- **Localization**: Türkçe ve İngilizce dil desteği
- **Custom Components**: Yeniden kullanılabilir UI bileşenleri
- **Design System**: Tutarlı tasarım dili

## 📁 Proje Yapısı

```
EvdeSaglik/
├── App/                    # Ana uygulama dosyaları
├── Core/                   # Firebase ve AI yönetimi
│   ├── FirebaseAuthManager.swift
│   ├── FirestoreManager.swift
│   ├── OpenRouterDeepseekManager.swift
│   └── UserManager.swift
├── Models/                 # Veri modelleri
├── Views/                  # UI bileşenleri
│   ├── AuthView/          # Kimlik doğrulama
│   ├── MainAppView/       # Ana uygulama ekranı
│   ├── ProfileView/       # Profil yönetimi
│   ├── ChatbotView/       # AI asistan
│   └── [Feature Views]/   # Özellik ekranları
├── Utils/                  # Yardımcı sınıflar
│   ├── BaseViewModel.swift
│   ├── ValidationHelper.swift
│   ├── AppError.swift
│   └── Widgets/           # Özel UI bileşenleri
└── Resources/             # Kaynak dosyalar
```

## 🚀 Özellikler

### **Temel Özellikler**
- ✅ Kullanıcı kayıt/giriş sistemi
- ✅ Profil yönetimi ve kişiselleştirme
- ✅ AI destekli sağlık asistanı
- ✅ Doğal çözüm önerileri
- ✅ İlaç-gıda etkileşim kontrolü
- ✅ Kan tahlili sonuç analizi
- ✅ Hastalık tahmini
- ✅ Doktor bölüm önerisi

### **Gelişmiş Özellikler**
- ✅ Geçmiş kayıtları görüntüleme
- ✅ Çoklu dil desteği (TR/EN)
- ✅ Responsive tasarım
- ✅ Offline çalışma desteği
- ✅ Güvenli veri saklama

## 🔧 Geliştirici Bilgileri

**Geliştirici**: Gökhan Kaya  
**Web Sitesi**: [gkhkaya.info](https://gkhkaya.info)  
**Versiyon**: 1.0.0

## 📱 Sistem Gereksinimleri

- **iOS**: 18.5+
- **Xcode**: 16.0+
- **Swift**: 5.9+

## 🛠️ Kurulum

1. Projeyi klonlayın
2. `pod install` komutunu çalıştırın
3. Firebase yapılandırmasını tamamlayın
4. Xcode'da projeyi açın ve çalıştırın

## 📄 Lisans

Bu proje özel bir uygulamadır. Tüm hakları saklıdır.

---

*Evde Sağlık - Sağlığınız evde başlar* 🏠💚
