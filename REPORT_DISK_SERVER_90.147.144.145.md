# Report analisi spazio disco — server 90.147.144.145

**Data analisi:** 2026-04-18
**Host:** `dhomeka@90.147.144.145`
**Stato:** CRITICO — root partition al 100%

---

## 1. Sommario esecutivo

Il filesystem root `/dev/mapper/ubuntu--vg-ubuntu--lv` (98 GB totali) è occupato al **100%**: 94 GB usati, 126 MB liberi. La causa principale è **un singolo file di log Docker da 50 GB** appartenente al container `colonizzazioni_apache`, che ha un log driver `json-file` senza rotazione configurata e sta producendo log in livello `debug`.

In totale i log Docker di 11 container pesano circa **55 GB** (`/var/lib/docker/containers`), più 6.2 GB di volumi e 8.4 GB di layer `overlay2`.

**Intervento minimo per tornare operativi: troncare il log da 50 GB → libera ~50 GB immediati.**

---

## 2. Occupazione filesystem

```
Filesystem                         Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv   98G   94G  126M 100% /
/dev/sda2                          974M  219M  688M  25% /boot
```

### Top directory (livello 1)

| Directory    | Dimensione |
|--------------|------------|
| `/var`       | 74 G       |
| `/home`      | 22 G       |
| `/usr`       | 1.7 G      |
| `/lib`       | 1.2 G      |
| `/snap`      | 584 M      |
| `/opt`       | 215 M      |

### Drill-down su `/var`

| Path             | Size |
|------------------|------|
| `/var/lib/docker`| 70 G |
| `/var/log/journal`| 3.7 G|
| `/var/opt`       | 447 M|
| `/var/cache`     | 101 M|

### Drill-down su `/var/lib/docker`

| Path                          | Size |
|-------------------------------|------|
| `/var/lib/docker/containers`  | **55 G** ← log JSON |
| `/var/lib/docker/overlay2`    | 8.4 G |
| `/var/lib/docker/volumes`     | 6.2 G |
| `/var/lib/docker/image`       | 11 M  |

---

## 3. Container e log: i colpevoli

Driver log di default: `json-file` senza `max-size`/`max-file` (`/etc/docker/daemon.json` **assente**). Nessuna rotazione dei log dei container.

### Top file `*-json.log`

| Dimensione | Container                   | Immagine                        |
|-----------:|-----------------------------|---------------------------------|
| **50 G**   | `colonizzazioni_apache`     | `wodby/apache:latest`           |
| 2.3 G      | `colonizzazioni_php`        | `wodby/php:7.1-dev-4.11.8`      |
| 661 M      | `storiedigitali_apache`     | `wodby/apache:2.4-4.3.1`        |
| 446 M      | `risorse_colo_apache`       | `wodby/apache:2.4-4.3.1`        |
| 389 M      | `colonizzazioni_dog_crond`  | `wodby/drupal-php:8.2-dev-...`  |
| 356 M      | `colonizzazioni_dog_php`    | `wodby/drupal-php:8.2-dev-...`  |
| 298 M      | *(container non mappato)*   | —                               |
| 284 M      | `colonizzazioni_dog_apache` | `wodby/apache:latest`           |
| 222 M      | *(container non mappato)*   | —                               |
| 110 M      | *(container non mappato)*   | —                               |

**Totale log top 10 ≈ 55 GB.**

### Stato `docker system df`

```
TYPE              TOTAL  ACTIVE  SIZE      RECLAIMABLE
Images            12     12      3.07 GB   15.5 MB (0%)
Containers        18     18      324 MB    0 B (0%)
Local Volumes     9      5       6.56 GB   219 MB (3%)
Build Cache       0      0       0 B       0 B
```

Tutte le 18 istanze sono `Up` da 8–11 mesi (nessun riavvio recente): il log del container `colonizzazioni_apache` è cresciuto incontrollatamente per via del livello `debug` di Apache (`mod_proxy_fcgi`, `authz_core` in DEBUG) che registra diverse righe per ogni richiesta HTTP.

Esempio log (ultime righe):
```
[proxy_fcgi:debug] [...] AH01076: url: fcgi://php:9000/.../index.php
[proxy_fcgi:debug] [...] AH01078: serving URL fcgi://php:9000/.../index.php
[proxy:debug]      [...] AH00942: FCGI: has acquired connection for (php)
[proxy:debug]      [...] AH00944: connecting fcgi://php:9000/...
GET /risorse_omc/items/browse?tags=... HTTP/1.1" 200 930
```

---

## 4. Altri contributori rilevanti

### `/home/dhomeka` (22 GB)

| Directory                              | Size |
|----------------------------------------|------|
| `dh.unica_omeka.s/web`                 | 8.1 G |
| `risorse_colo/web`                     | 4.0 G |
| `dh.unica_omeka.s/.git`                | 1.8 G |
| `dh.unica_risorgimento`                | 1.3 G |
| `glossari`                             | 1.2 G |
| `dh.unica_colonizzazioni`              | 1.1 G |
| `colonizzazioninterne`                 | 994 M |
| `400anni_humanities`                   | 916 M |
| `.cache`                               | 911 M |
| `colonizzazioninterne_dog`             | 823 M |

### `/var/log/journal` (3.7 GB)

Journald senza cap. Configurazione di default mantiene archivi per spazio indefinito.

---

## 5. Piano di pulizia e riduzione spazio

Azioni suddivise per **impatto** e **rischio**. Eseguire nell'ordine: **fase 1 sblocca subito il sistema**, le successive consolidano.

### FASE 1 — Emergenza (recupero immediato ~53 GB, rischio basso)

Troncare i log JSON dei container senza fermare i servizi. Il log del file è aperto dal daemon: un `truncate -s 0` lavora live.

```bash
# Troncamento del log da 50 GB (colonizzazioni_apache)
sudo truncate -s 0 /var/lib/docker/containers/4e8a46ac61487bb8fcdc3529826a98e1dfd0a85e5d4e9f0ed14bbf71883a1aaf/*-json.log

# In bulk per TUTTI i container (sicuro su json-file driver):
sudo find /var/lib/docker/containers/ -name "*-json.log" -exec truncate -s 0 {} \;

# Riduzione journal (recupera ~3 GB, tiene ultimi 500 MB)
sudo journalctl --vacuum-size=500M
```

**Liberazione attesa:** ~55 GB (disk usage `/` scende da 100 % a ~44 %).

### FASE 2 — Prevenire recidive (CRITICO)

#### 2a. Configurare rotazione globale log Docker

Creare `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5",
    "compress": "true"
  }
}
```

Riavviare il daemon:

```bash
sudo systemctl restart docker
```

> Nota: la nuova policy si applica solo a container creati/ricreati dopo il restart. I container esistenti mantengono la vecchia config finché non vengono rimossi e ricreati (`docker compose down && docker compose up -d` nei vari progetti in `/home/dhomeka/*/`).

#### 2b. Abbassare il livello log Apache nei container `wodby/apache`

Il livello `debug` è produzione-inadatto. Configurare via variabile d'ambiente wodby:

```yaml
# docker-compose.yml di ciascun progetto
environment:
  APACHE_LOG_LEVEL: warn   # invece di debug
```

Priorità: `colonizzazioni_apache` (il produttore dei 50 GB).

#### 2c. Cap journal systemd

`/etc/systemd/journald.conf`:

```ini
[Journal]
SystemMaxUse=1G
SystemMaxFileSize=100M
MaxRetentionSec=1month
```

```bash
sudo systemctl restart systemd-journald
```

### FASE 3 — Pulizia Docker opportunistica (recupero atteso 1-3 GB)

```bash
# Rimuove immagini dangling, build cache, network inutilizzati
sudo docker system prune -f

# Volumi orfani (ATTENZIONE: verificare con `docker volume ls -f dangling=true` prima)
sudo docker volume ls -f dangling=true
# Se la lista è quella attesa:
sudo docker volume prune -f
```

Dal report `docker system df` il recuperabile è limitato (~234 MB immediati) ma la pulizia periodica evita accumuli futuri.

### FASE 4 — Pulizia `/home/dhomeka` (opzionale, recupero 1–5 GB)

Da valutare con l'utente prima di toccare:

| Azione                                                  | Recupero |
|---------------------------------------------------------|----------|
| `git gc --aggressive` in `dh.unica_omeka.s/.git` (1.8G) | ~0.5–1 G |
| Pulizia `~/.cache` (911 M)                              | ~900 M   |
| Verifica `web/` dei progetti Omeka per file derivati/temp (thumbnails, derivative, zip di backup) | variabile |
| Review `~/.npm` (105 M)                                 | ~100 M   |

### FASE 5 — Monitoraggio continuo

Aggiungere cron settimanale o unità systemd timer:

```bash
# /etc/cron.weekly/docker-log-audit
#!/bin/sh
MAX=536870912   # 512 MB
find /var/lib/docker/containers -name "*-json.log" -size +${MAX}c \
  -exec truncate -s 0 {} \; \
  -exec logger -t docker-log-audit "Troncato log oversize: {}" \;
```

Alerting su disco (`df` via cron + mail, o prometheus node-exporter con alert a ≥80 %).

---

## 6. Comandi completi "copia-incolla" per intervento immediato

```bash
# 1. Backup rapido dei log grandi per eventuale analisi (OPZIONALE, solo se c'è spazio altrove)
# Saltabile: i log sono solo debug, nessun valore di business

# 2. Tronca TUTTI i log json-file Docker (nessun downtime)
sudo find /var/lib/docker/containers/ -name "*-json.log" -exec truncate -s 0 {} \;

# 3. Pulizia journald
sudo journalctl --vacuum-size=500M

# 4. Configura limite log driver
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "5", "compress": "true" }
}
EOF
sudo systemctl restart docker

# 5. Verifica
df -h /
sudo du -sh /var/lib/docker/containers
docker ps
```

Dopo il restart Docker: tutti i container con `restart: unless-stopped` si riavvieranno automaticamente. Verificare che tutti i siti rispondano.

---

## 7. Raccomandazioni strategiche

1. **Riavviare i container dopo aver modificato `daemon.json`**: senza `docker compose up -d` su ciascun progetto, i container esistenti mantengono la vecchia policy senza limite. Programmare finestra di manutenzione.
2. **Livello log di produzione**: standardizzare `APACHE_LOG_LEVEL=warn` e `PHP_DEBUG=0` nei `docker-compose.yml` di ambienti live. Il setup attuale sembra una configurazione "dev" portata in esercizio.
3. **Allargare il volume**: 98 GB per 7 applicazioni Drupal/Omeka multi-tenant è al limite. Considerare resize del LV `ubuntu--vg-ubuntu--lv` (se il VG ha spazio libero: `sudo vgs` per verificare) oppure aggiunta di un disco separato per `/var/lib/docker`.
4. **Backup / retention**: al momento non si nota una strategia di backup fuori host (directory `backups/` da 460 K). Da definire politica retention separata prima di eventuale resize.
