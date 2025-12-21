# Risorse - Digital Humanities Repository

[![Omeka S](https://img.shields.io/badge/Omeka%20S-4.x-blue.svg)](https://omeka.org/s/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED.svg?logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE.md)

> Repository digitale per la conservazione e condivisione di risorse del Dipartimento di Digital Humanities dell'Università di Cagliari

## 📖 Panoramica

**Risorse** è un'installazione di [Omeka S](https://omeka.org/s/) dedicata all'archiviazione, gestione e disseminazione di **oggetti digitali** prodotti nell'ambito dei progetti di ricerca del [Dipartimento di Digital Humanities](https://dh.unica.it) dell'Università di Cagliari.

Il repository fa parte dell'ecosistema [storia.dh.unica.it](https://storia.dh.unica.it), il portale della Storia Digitale UniCA che sviluppa applicativi e flussi di lavoro digitali per la ricerca storica. Risorse centralizza e preserva le risorse digitali di progetti quali:

- **[Colonizzazioni interne e migrazioni](https://storia.dh.unica.it/colonizzazioninterne)** - Catalogazione e geolocalizzazione dei progetti di popolamento promossi in Europa (XVI-XVIII secolo)
- **[Atlante digitale di Storia Marittima](https://storia.dh.unica.it/asmsa/)** - Storia marittima del Regno di Sardegna e connettività mediterranee
- **[Storie Digitali](https://storia.dh.unica.it/storiedigitali/)** - Progetti didattici di storia digitale e pubblica del LUDiCa
- **[Archivio Digitale del Risorgimento in Sardegna](https://storia.dh.unica.it/archiviodigitalerisorgimento/)** - Studio della partecipazione della Sardegna all'unificazione italiana
- **[LUDiCa](https://ludica.dh.unica.it/)** - Laboratorio di Umanistica Digitale per l'integrazione tra metodologie umanistiche e tecnologie digitali

### 🎓 Cosa sono le Digital Humanities?

Le **Digital Humanities** (Umanistica Digitale) rappresentano l'intersezione tra discipline umanistiche e tecnologie digitali. Combinano metodi computazionali, strumenti di analisi digitale e approcci critici per:

- **Preservare** il patrimonio culturale in formato digitale
- **Analizzare** grandi corpus testuali e collezioni multimediali
- **Visualizzare** dati storici, letterari e culturali
- **Condividere** risorse scientifiche secondo principi Open Access
- **Collaborare** in progetti di ricerca interdisciplinari

### 🎯 A cosa serve Risorse?

Questo repository Omeka S consente di:

- ✅ **Catalogare** oggetti digitali (documenti, immagini, audio, video, dataset)
- ✅ **Organizzare** collezioni tematiche e mostre virtuali
- ✅ **Descrivere** risorse con metadati standardizzati (Dublin Core, METS, MODS, CDWALite)
- ✅ **Esporre** dati tramite protocolli interoperabili (OAI-PMH, IIIF)
- ✅ **Pubblicare** contenuti accessibili via web per ricercatori, studenti e pubblico
- ✅ **Integrare** risorse con altri sistemi e repository istituzionali

## 🔌 Interoperabilità e Standard Metadata

Grazie al modulo **OAI-PMH Repository**, Risorse supporta l'esposizione dei metadati secondo diversi formati standard:

| Formato | Descrizione | Uso principale |
|---------|-------------|----------------|
| **Dublin Core** | Standard descrittivo base | Interoperabilità generale |
| **METS** | Metadata Encoding & Transmission Standard | Oggetti digitali complessi, biblioteche digitali |
| **MODS** | Metadata Object Description Schema | Risorse bibliografiche |
| **CDWALite** | Categories for the Description of Works of Art | Opere d'arte e beni culturali |

Il protocollo **OAI-PMH** (Open Archives Initiative Protocol for Metadata Harvesting) permette a:
- Aggregatori nazionali ed europei (es. Europeana, CulturaItalia) di raccogliere automaticamente i metadati
- Repository istituzionali di sincronizzare le collezioni
- Motori di ricerca specializzati di indicizzare le risorse

Inoltre, grazie al modulo **MarcXmlExport**, è possibile esportare le risorse in formato **MARCXML** (UNIMARC) per l'integrazione con sistemi bibliotecari tradizionali.

## 🚀 Avvio del Progetto in Locale

### Prerequisiti

- [Docker](https://docs.docker.com/get-docker/) >= 20.10
- [Docker Compose](https://docs.docker.com/compose/install/) >= 1.29
- Git

### Installazione

1. **Clone del repository:**
   ```bash
   git clone git@github.com:Unica-dh/risorse_colo.git
   cd risorse_colo
   ```

2. **Verifica configurazione:**
   
   Il file `.env` contiene le variabili di configurazione. I valori predefiniti sono adatti per l'ambiente di sviluppo locale:
   ```env
   PROJECT_NAME=risorse_colo
   DB_NAME=php
   DB_USER=php
   DB_PASSWORD=php
   DB_HOST=mariadb
   PHP_TAG=7.4-dev-4.16.2
   MARIADB_TAG=10.5-3.9.1
   APACHE_TAG=2.4-4.3.1
   ```

3. **Avvio dei container:**
   ```bash
   docker-compose up -d
   ```

4. **Verifica che i servizi siano attivi:**
   ```bash
   docker-compose ps
   ```
   
   Dovresti vedere tre container in esecuzione:
   - `risorse_colo_apache` (porta 8000)
   - `risorse_colo_php`
   - `risorse_colo_mariadb`

5. **Accesso all'applicazione:**
   
   Apri il browser all'indirizzo: **http://localhost:8000**

### 🔐 Reset Password Admin (per uso locale)

Se hai bisogno di accedere all'area amministrativa in locale, puoi resettare la password dell'admin:

1. **Genera l'hash della nuova password:**
   ```bash
   docker exec -i risorse_colo_php php -r 'echo password_hash("TuaNuovaPassword", PASSWORD_DEFAULT), PHP_EOL;'
   ```
   Copia l'hash generato (stringa che inizia con `$2y$...`)

2. **Accedi al database MariaDB:**
   ```bash
   docker exec -it risorse_colo_mariadb mysql -uphp -pphp php
   ```

3. **Visualizza gli utenti admin:**
   ```sql
   SELECT id, email, name, role FROM user WHERE role LIKE '%admin%';
   ```

4. **Aggiorna la password (sostituisci EMAIL e HASH):**
   ```sql
   UPDATE user 
   SET password_hash = '$2y$10$HASH_GENERATO_AL_PASSO_1', 
       modified = NOW() 
   WHERE email = 'tua-email@example.com';
   ```

5. **Verifica e esci:**
   ```sql
   SELECT email, LENGTH(password_hash) FROM user WHERE email = 'tua-email@example.com';
   QUIT;
   ```

6. **Accedi all'admin panel:**
   
   Vai su http://localhost:8000/admin e usa le nuove credenziali.

## 📁 Struttura del Progetto

```
risorse_colo/
├── docker-compose.yml      # Configurazione servizi Docker
├── .env                    # Variabili d'ambiente
├── docroot/                # Document root Apache
├── web/                    # Installazione Omeka S
│   ├── application/        # Core Omeka S
│   ├── modules/            # Moduli installati
│   │   ├── OaiPmhRepository/
│   │   ├── MarcXmlExport/
│   │   ├── IiifServer/
│   │   └── ...
│   ├── themes/             # Temi
│   ├── files/              # File caricati dagli utenti
│   └── config/             # Configurazione database
├── mariadb-init/           # Script inizializzazione DB
└── backup/                 # Backup database
```

## 🔧 Comandi Utili

```bash
# Fermare i container
docker-compose down

# Riavviare i servizi
docker-compose restart

# Visualizzare i log
docker-compose logs -f

# Accesso shell container PHP
docker exec -it risorse_colo_php sh

# Backup database
docker exec risorse_colo_mariadb mysqldump -uphp -pphp php > backup/backup_$(date +%Y%m%d_%H%M%S).sql

# Ripristino database
docker exec -i risorse_colo_mariadb mysql -uphp -pphp php < backup/backup_YYYYMMDD_HHMMSS.sql
```

## 📚 Moduli Installati

Il progetto include numerosi moduli per estendere le funzionalità di Omeka S:

| Modulo | Descrizione |
|--------|-------------|
| **OaiPmhRepository** | Esposizione metadati tramite protocollo OAI-PMH |
| **MarcXmlExport** | Export MARCXML (UNIMARC) per sistemi bibliotecari |
| **IiifServer** | Server IIIF per immagini ad alta risoluzione |
| **Mapping** | Geolocalizzazione e mappe interattive |
| **Timeline** | Visualizzazioni cronologiche |
| **BulkImport** | Importazione massiva da CSV, XML, OAI-PMH |
| **MetadataBrowse** | Navigazione avanzata per metadati |
| **ValueSuggest** | Autocompletamento da vocabolari controllati |

## 🌐 Link Utili

- **Sito produzione:** [https://storia.dh.unica.itrisorse](https://storia.dh.unica.itrisorse)
- **Digital Humanities UniCA:** [https://dh.unica.it](https://dh.unica.it)
- **Documentazione Omeka S:** [https://omeka.org/s/docs/](https://omeka.org/s/docs/)
- **OAI-PMH Endpoint:** [https://storia.dh.unica.itrisorse/oai](https://storia.dh.unica.itrisorset/oai)

## 📄 Licenza

Questo progetto è distribuito sotto licenza [GPL-3.0](LICENSE.md).

---

**Università degli Studi di Cagliari**  
Dipartimento di Digital Humanities  
© 2025