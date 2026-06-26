import 'package:flutter/material.dart';
import '../../core/theme/v_theme.dart';

// ── Gizlilik Politikası ───────────────────────────────────────────────────────

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalPage(
      title: 'Gizlilik Politikası',
      lastUpdated: '13 Nisan 2026',
      sections: const [
        _Section(
          title: 'Giriş',
          body:
              'Vitra olarak kullanıcılarımızın gizliliğini en yüksek önceliklerimizden biri olarak '
              'kabul ediyoruz. Bu Gizlilik Politikası; Vitra uygulamasını kullandığınızda hangi '
              'verileri topladığımızı, bu verileri nasıl işlediğimizi, kimlerle paylaştığımızı ve '
              'haklarınızın neler olduğunu açık ve anlaşılır biçimde ortaya koymaktadır.\n\n'
              'Uygulamayı kullanmaya devam ederek bu politikayı okuduğunuzu ve kabul ettiğinizi '
              'beyan etmiş olursunuz. Politikayı kabul etmiyorsanız lütfen uygulamayı kullanmayın.',
        ),
        _Section(
          title: '1. Topladığımız Veriler',
          body:
              'Hesap Bilgileri\n'
              'E-posta adresi, görünen ad. Google ile giriş yapıyorsanız profil fotoğrafınız da '
              'otomatik olarak alınır.\n\n'
              'Sağlık ve Beslenme Verileri\n'
              'Yaş, cinsiyet, boy, kilo, günlük kalori ve su tüketimi, yemek kayıtları, '
              'rutin takip verileri ve streak (seri) bilgisi.\n\n'
              'Tercih Verileri\n'
              'Bildirim ayarları, hedef kalori/su miktarı, aktivite seviyesi, uygulama dili.\n\n'
              'Kullanım Verileri\n'
              'Uygulama içi etkileşimler, oturum süresi ve özellik kullanım istatistikleri. '
              'Bu veriler Firebase Analytics aracılığıyla anonim olarak toplanır.',
        ),
        _Section(
          title: '2. Verileri Nasıl Kullanırız',
          body:
              '• Uygulamanın temel işlevlerini sağlamak (kalori, su ve rutin takibi)\n'
              '• Kişiselleştirilmiş AI koç önerileri ve yemek analizi sunmak\n'
              '• Verilerinizi cihazlar arasında senkronize etmek\n'
              '• Hataları tespit etmek ve uygulama performansını sürekli iyileştirmek\n'
              '• Abonelik ve satın alma işlemlerini yönetmek\n'
              '• Yasal yükümlülüklerimizi yerine getirmek',
        ),
        _Section(
          title: '3. Üçüncü Taraf Hizmetler',
          body:
              'Firebase (Google LLC)\n'
              'Kimlik doğrulama, Firestore veritabanı, Analytics ve Crashlytics hizmetleri için '
              'kullanılır. Verileriniz Google\'ın gizlilik politikasına tabidir.\n\n'
              'Google Gemini API\n'
              'Yemek fotoğrafı analizi ve AI koç yanıtları için metin/görsel verileriniz anlık '
              'olarak işlenir. Bu veriler yalnızca analiz süresince kullanılır; Google tarafından '
              'kalıcı olarak saklanmaz.\n\n'
              'RevenueCat\n'
              'Premium abonelik yönetimi için kullanılır. Ödeme bilgilerinize (kart numarası vb.) '
              'hiçbir zaman erişimimiz yoktur; bu bilgiler doğrudan App Store / Play Store '
              'tarafından işlenir.\n\n'
              'Google AdMob\n'
              'Ücretsiz kullanıcılara reklam gösterimi için kullanılır. Reklamlar, cihazınızın '
              'reklamcılık kimliğine göre kişiselleştirilebilir. Kişiselleştirmeyi cihaz '
              'ayarlarınızdan devre dışı bırakabilirsiniz.',
        ),
        _Section(
          title: '4. Veri Güvenliği',
          body:
              'Verileriniz Google Cloud altyapısında, endüstri standardı AES-256 şifrelemesiyle '
              'saklanır. Uygulama ile sunucular arasındaki tüm iletişim TLS/HTTPS üzerinden '
              'gerçekleştirilir.\n\n'
              'Hesabınıza yalnızca siz erişebilirsiniz. Şifreniz asla açık metin olarak '
              'saklanmaz; Firebase Auth\'ın güvenli karma algoritmaları kullanılır. '
              'Vitra çalışanlarının şifrenize erişimi yoktur.',
        ),
        _Section(
          title: '5. Veri Saklama Süresi',
          body:
              'Verileriniz hesabınız aktif olduğu sürece saklanır. Hesabınızı sildiğinizde '
              'kişisel verilerinizin tamamı Firestore\'dan 30 gün içinde kalıcı olarak '
              'temizlenir.\n\n'
              'Firebase Analytics aracılığıyla toplanan anonim kullanım istatistikleri, '
              'bireysel kimliğinizle ilişkilendirilmeksizin toplu hâlde daha uzun süre '
              'saklanabilir.',
        ),
        _Section(
          title: '6. Kullanıcı Hakları',
          body:
              'Türkiye\'de mukim kullanıcılar olarak 6698 sayılı KVKK kapsamındaki haklarınız '
              'saklıdır. Bu haklar şunlardır:\n\n'
              '• Kişisel verilerinizin işlenip işlenmediğini öğrenme\n'
              '• İşlenmişse buna ilişkin bilgi talep etme\n'
              '• Yanlış veya eksik verilerin düzeltilmesini isteme\n'
              '• Verilerin silinmesini ya da yok edilmesini talep etme '
              '(Ayarlar → Profil → Hesabı Sil)\n'
              '• Veriler üzerinde gerçekleştirilen işlemlerin üçüncü kişilere bildirilmesini isteme\n'
              '• Verilerin yalnızca otomatik sistemler aracılığıyla analiz edilmesine itiraz etme',
        ),
        _Section(
          title: '7. Çocukların Gizliliği',
          body:
              'Vitra, 13 yaşın altındaki bireylere yönelik bir uygulama değildir ve bu yaş '
              'grubuna ait kişisel verileri bilerek toplamaz. 13 yaşın altında bir kullanıcıya '
              'ait veri topladığımızı fark ettiğimizde söz konusu veriler derhal silinir.',
        ),
        _Section(
          title: '8. Politika Güncellemeleri',
          body:
              'Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişiklikler olduğunda '
              'uygulama içi bildirim ve/veya e-posta yoluyla önceden bilgilendirilirsiniz. '
              'Güncelleme sonrasında uygulamayı kullanmaya devam etmeniz, yeni politikayı '
              'kabul ettiğiniz anlamına gelir.',
        ),
        _Section(
          title: '9. İletişim',
          body:
              'Gizlilik politikasına ilişkin sorularınız veya talepleriniz için bizimle '
              'iletişime geçebilirsiniz:\n\n'
              'E-posta: privacy@vitrasaglik.com\n\n'
              'Taleplerinizi en geç 30 gün içinde yanıtlamayı taahhüt ederiz.',
        ),
      ],
    );
  }
}

// ── Kullanım Koşulları ────────────────────────────────────────────────────────

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalPage(
      title: 'Kullanım Koşulları',
      lastUpdated: '13 Nisan 2026',
      sections: const [
        _Section(
          title: 'Giriş',
          body:
              'Bu Kullanım Koşulları, Vitra mobil uygulamasını ("Uygulama") kullanımınızı '
              'düzenleyen yasal bir sözleşmedir. Uygulamayı indirerek, yükleyerek veya '
              'kullanmaya başlayarak bu koşulların tamamını okuduğunuzu ve kabul ettiğinizi '
              'beyan edersiniz. Koşulları kabul etmiyorsanız lütfen uygulamayı kullanmayın.',
        ),
        _Section(
          title: '1. Hizmet Tanımı',
          body:
              'Vitra; kalori takibi, su takibi, rutin yönetimi ve yapay zeka destekli kişisel '
              'beslenme koçluğu sunan bir mobil sağlık uygulamasıdır.\n\n'
              'Uygulama, Türkiye merkezli olarak sunulmakta olup Apple App Store ve '
              'Google Play Store aracılığıyla erişilebilir.',
        ),
        _Section(
          title: '2. Hesap ve Güvenlik',
          body:
              'Hesap oluşturarak doğru, güncel ve eksiksiz bilgi sağlamayı kabul edersiniz. '
              'Hesabınızın güvenliğinden ve hesabınız üzerinden gerçekleştirilen tüm '
              'işlemlerden yalnızca siz sorumlusunuz.\n\n'
              'Şifrenizi asla başkalarıyla paylaşmayın. Hesabınıza yetkisiz erişim '
              'gerçekleştiğini fark ederseniz derhal privacy@vitrasaglik.com adresine '
              'bildirin.\n\n'
              'Yanıltıcı veya eksik bilgi sağlandığı tespit edildiğinde hesabınız '
              'önceden bildirim yapılmaksızın askıya alınabilir.',
        ),
        _Section(
          title: '3. Kabul Edilebilir Kullanım',
          body:
              'Uygulamayı yalnızca kişisel ve ticari olmayan amaçlarla kullanabilirsiniz. '
              'Aşağıdaki kullanımlar kesinlikle yasaktır:\n\n'
              '• Uygulamayı tersine mühendislik, kopyalama veya türev çalışma oluşturma amacıyla kullanmak\n'
              '• Bot, scraper veya otomatik sistemlerle uygulamaya erişmek\n'
              '• Başka kullanıcılara zarar verecek ya da hizmetlerimizi kesintiye uğratacak eylemler gerçekleştirmek\n'
              '• Yanlış sağlık bilgisi yaymak amacıyla AI özelliklerini kullanmak\n'
              '• Uygulamayı yasadışı herhangi bir amaç doğrultusunda kullanmak',
        ),
        _Section(
          title: '4. Sağlık Uyarısı ve AI Sınırlamaları',
          body:
              'Vitra bir sağlık ve yaşam tarzı uygulamasıdır; ancak tıbbi tavsiye, teşhis '
              'veya tedavi sunmaz.\n\n'
              'AI koç önerileri ve kalori tahminleri genel bilgilendirme amaçlıdır. '
              'Herhangi bir sağlık durumunuz için mutlaka yetkili bir sağlık uzmanına '
              'danışmanızı öneririz.\n\n'
              'Acil bir tıbbi durumda uygulamayı değil, 112 acil servisini arayın.',
        ),
        _Section(
          title: '5. Premium Abonelik',
          body:
              'Vitra; temel özelliklere ücretsiz erişim sağlayan ve gelişmiş özellikleri '
              'kapsayan Premium olmak üzere iki kullanım seviyesi sunar.\n\n'
              'Satın Alma\n'
              'Premium abonelik, App Store veya Play Store üzerinden aylık ya da yıllık '
              'olarak satın alınabilir.\n\n'
              'İptal\n'
              'Aboneliği istediğiniz zaman ilgili mağaza üzerinden iptal edebilirsiniz. '
              'İptal işlemi mevcut abonelik döneminin sonunda geçerli olur; '
              'kalan süre için iade yapılmaz.\n\n'
              'Fiyat Değişiklikleri\n'
              'Abonelik fiyatları değişebilir. Değişiklikler en az 30 gün öncesinde '
              'uygulama içi bildirim ile duyurulur.',
        ),
        _Section(
          title: '6. Fikri Mülkiyet',
          body:
              'Uygulamanın tüm içeriği, tasarımı, arayüzü, logosu, kod tabanı ve '
              'dokümantasyonu Vitra\'ya aittir ve Türk Fikir ve Sanat Eserleri Kanunu '
              'ile uluslararası telif hakkı yasalarıyla korunmaktadır.\n\n'
              'Kullanıcılara, bu koşullar çerçevesinde uygulamayı kişisel olarak '
              'kullanmak için sınırlı, devredilemez ve münhasır olmayan bir lisans verilmektedir.',
        ),
        _Section(
          title: '7. Sorumluluk Sınırlaması',
          body:
              'Vitra, uygulamanın kesintisiz, hatasız veya tamamen güvenli çalışacağını '
              'garanti etmez. Uygulama "mevcut hâliyle" sunulmaktadır.\n\n'
              'Vitra; veri kaybı, hizmet kesintisi, AI çıktılarındaki hatalar veya '
              'kullanıcıların bu çıktılara dayanarak aldığı kararlardan doğan doğrudan '
              'ya da dolaylı zararlardan sorumlu tutulamaz.',
        ),
        _Section(
          title: '8. Hesap Feshi',
          body:
              'Bu koşulları ihlal etmeniz durumunda hesabınız önceden bildirim '
              'yapılmaksızın askıya alınabilir veya kalıcı olarak kapatılabilir.\n\n'
              'Hesabınızı istediğiniz zaman Ayarlar → Profil → Hesabı Sil yoluyla '
              'kendiniz silebilirsiniz.',
        ),
        _Section(
          title: '9. Koşul Güncellemeleri',
          body:
              'Bu koşulları zaman zaman güncelleyebiliriz. Önemli değişiklikler '
              'yürürlüğe girmeden en az 14 gün önce uygulama içi bildirim ve/veya '
              'e-posta aracılığıyla duyurulur.\n\n'
              'Güncelleme sonrasında uygulamayı kullanmaya devam etmeniz, '
              'yeni koşulları kabul ettiğiniz anlamına gelir.',
        ),
        _Section(
          title: '10. Uygulanacak Hukuk ve Yetki',
          body:
              'Bu Kullanım Koşulları, Türkiye Cumhuriyeti hukukuna tabidir. '
              'Taraflar arasında doğabilecek her türlü uyuşmazlıkta İstanbul mahkemeleri '
              'münhasır yetki alanına sahiptir.\n\n'
              'İletişim: legal@vitrasaglik.com',
        ),
      ],
    );
  }
}

// ── Ortak Sayfa Yapısı ────────────────────────────────────────────────────────

class _LegalPage extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_Section> sections;

  const _LegalPage({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;

    return Scaffold(
      backgroundColor: vc.bg,
      appBar: AppBar(
        backgroundColor: vc.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: vc.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: vc.text,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
        children: [
          Text(
            'Son güncelleme: $lastUpdated',
            style: TextStyle(fontSize: 12, color: vc.textSub),
          ),
          const SizedBox(height: 20),
          ...sections.map((s) => _SectionWidget(section: s, vc: vc)),
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}

class _SectionWidget extends StatelessWidget {
  final _Section section;
  final VColors vc;

  const _SectionWidget({required this.section, required this.vc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: vc.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              fontSize: 14,
              color: vc.textSub,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
