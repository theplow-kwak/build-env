# MCTP over SMBUS

## MCTP 프로토콜 구조

**MCTP(Management Component Transport Protocol)**의 프로토콜 구조는 다양한 물리적 매체 위에서 일관된 관리 통신을 지원하기 위해 **계층적이고 패킷 기반의 구조**로 설계되었습니다. 이 구조의 핵심은 물리 계층의 특성에 구애받지 않으면서도 시스템 내부 장치들 간의 정교한 데이터 교환을 가능하게 하는 **매체 독립성(Transport Independence)**에 있습니다.

MCTP 프로토콜 구조의 주요 구성 요소와 그 역할을 더 큰 맥락에서 논의하면 다음과 같습니다.

### 1. 일반적인 패킷 구조 (Generic Packet Structure)

MCTP 패킷은 물리 계층과 독립적인 공통 필드와 특정 매체에 종속적인 필드가 결합된 형태를 띱니다.

* **매체 특정 헤더 및 트레일러 (Medium-specific Header/Trailer):** SMBus나 PCIe VDM과 같은 특정 물리 버스에서 패킷을 전달하기 위한 물리 주소와 프레임 정보, 그리고 CRC나 체크섬과 같은 데이터 무결성 체크 필드를 포함합니다.
* **MCTP 전송 헤더 (Transport Header):** 모든 MCTP 패킷에 공통으로 존재하는 **32비트 헤더**입니다. 여기에는 버전 정보, 목적지 및 출발지 **EID(Endpoint ID)**, 패킷 시퀀스 번호, 메시지 태그 등이 포함되어 라우팅과 메시지 조립을 지원합니다.
* **메시지 본체 (Message Body):** 실제 전달하려는 관리 데이터가 담기는 부분으로, 메시지 유형(Message Type)과 해당 유형에 특화된 헤더 및 데이터로 구성됩니다.

### 2. 메시지 조립 및 분해 (Assembly & Disassembly)

MCTP 구조는 큰 데이터를 효율적으로 전송하기 위해 메시지를 여러 패킷으로 쪼개고 수신 측에서 다시 합치는 메커니즘을 내장하고 있습니다 .

* **SOM 및 EOM 비트:** 전송 헤더의 **SOM(Start Of Message)**과 **EOM(End Of Message)** 비트를 통해 해당 패킷이 메시지의 시작인지, 중간인지, 끝인지를 식별합니다.
* **패킷 시퀀스 번호 (Pkt Seq #):** 메시지가 여러 패킷으로 나뉠 때 각 패킷에 순차적인 번호를 부여하여, 수신 측에서 누락된 패킷을 감지하고 올바른 순서로 재조립할 수 있게 합니다.
* **기본 전송 단위 (BTU):** MCTP의 최소 공통 분모 크기는 **64바이트**입니다. 모든 MCTP 네트워크는 이 크기의 패킷을 라우팅할 수 있음을 보장해야 하며, 이는 서로 다른 매체 간의 브릿징 시 효율성을 극대화합니다.

### 3. 메시지 유형 및 상위 프로토콜 캡슐화

MCTP 구조의 강점은 하나의 전송 프로토콜 위에서 여러 종류의 상위 관리 데이터를 동시에 운반할 수 있다는 점입니다 .

* **메시지 유형 (Message Type):** 메시지 본체의 첫 번째 바이트에 위치하며, 해당 데이터가 MCTP 제어 메시지(0x00)인지, PLDM, NC-SI, 또는 제조사 정의 메시지인지를 구분합니다.
* **MCTP 제어 프로토콜 (Control Protocol):** 네트워크 초기화, EID 할당, 기능 발견 등을 수행하기 위한 전용 구조를 가집니다. 이 메시지들은 항상 단일 패킷(64바이트 이하)으로 전송되어야 하며, 요청과 응답을 매칭하기 위한 **인스턴스 ID(Instance ID)** 필드를 사용합니다.

### 4. 전체적인 맥락에서의 의의

MCTP 프로토콜 구조가 가지는 구조적 가치는 다음과 같습니다.

* **유연한 캡슐화:** NVMe 관리 메시지나 이더넷 트래픽(NC-SI) 등을 MCTP 구조 안에 싣고 전송할 수 있어 시스템 관리의 통합을 가능하게 합니다.
* **보안의 분리:** MCTP 구조 자체는 하위 전송에 집중하며, 기밀성이나 인증 같은 보안 요구사항은 MCTP가 실어나르는 **상위 계층 데이터 모델**에서 처리하도록 설계되었습니다 .
* **플랫폼 확장성:** 이러한 표준화된 구조 덕분에 서버, 워크스테이션부터 모바일 플랫폼에 이르기까지 제조사와 매체에 상관없이 동일한 관리 모델을 적용할 수 있습니다.

## eid, command code, message type on mctp/ smbus

**EID, Command Code, Message Type**은 MCTP와 SMBus 양쪽 사양에서 모두 언급되지만, **각각 물리 계층(SMBus)과 논리 전송 계층(MCTP)에서 담당하는 역할과 값이 서로 다릅니다.**

이해를 돕기 위해 각 항목별 차이점을 상세히 설명해 드립니다.

### 1. EID (Endpoint ID) vs Slave Address

* **MCTP의 EID:** MCTP 네트워크 내에서 장치를 식별하기 위한 **8비트 논리 주소**입니다. 인터넷의 IP 주소와 유사한 역할을 하며, 메시지 라우팅의 기준이 됩니다.
* **SMBus의 주소:** SMBus는 EID라는 개념이 없으며, 대신 **7비트 슬레이브 주소(Slave Address)**라는 **물리적 주소**를 사용합니다.
* **차이점:** MCTP는 EID를 통해 논리적으로 누구에게 보낼지 결정하고, 실제 전송 시에는 이 EID를 해당 버스의 물리적 슬레이브 주소로 해석(Resolution)하여 보냅니다.

### 2. Command Code (명령 코드)

이 부분이 가장 혼동되기 쉬운 부분입니다.

* **SMBus의 Command Code:** SMBus 프로토콜 프레임 내에 존재하는 필드입니다. **MCTP over SMBus 바인딩 규격**에서는 이 값을 **항상 0x0F로 고정**하여 사용합니다. 이는 해당 SMBus 트랜잭션이 일반 데이터가 아니라 'MCTP 패킷'임을 나타내는 식별자 역할을 합니다.
* **MCTP의 Command Code:** MCTP **제어 메시지(Type 0x00)** 내부에 존재하는 필드입니다. 이는 `Set Endpoint ID(0x01)`, `Get MCTP Version Support(0x04)` 등 실제 어떤 관리 작업을 수행할지를 지정하는 번호입니다.
* **차이점:** SMBus 레벨의 0x0F는 "이것은 MCTP다"라는 것을 알리고, 그 내부의 MCTP 제어 명령 코드는 "어떤 설정을 해라"라는 상세 동작을 지시합니다.

### 3. Message Type (메시지 유형)

* **MCTP의 Message Type:** MCTP 전송 헤더 뒤에 오는 데이터가 어떤 종류인지(예: 0x00은 제어 메시지, 0x04는 NVMe Express 관리 메시지 등)를 식별하는 **7비트 필드**입니다.
* **SMBus에서의 존재 여부:** **SMBus 자체 규격에는 Message Type이라는 필드가 없습니다.** 하지만 SMBus가 MCTP 패킷을 실어 나를 때(Encapsulation), MCTP의 Message Type 필드가 SMBus 데이터 바이트(Data Byte)의 일부로 포함되어 전송될 뿐입니다.
* **차이점:** Message Type은 전적으로 MCTP 계층의 개념이며, SMBus는 이를 단순한 데이터 페이로드의 일부로 취급하여 목적지까지 전달하는 역할만 수행합니다.

### 요약 비교표

| 항목 | 물리 계층 (SMBus/I2C) | 논리/전송 계층 (MCTP) |
| :--- | :--- | :--- |
| **주소 (Address)** | **Slave Address (7비트)**: 물리적인 선로 상의 장치 위치 | **EID (8비트)**: 논리적인 종단점 식별자 |
| **명령 (Command)** | **Command Code (0x0F)**: "이 트랜잭션은 MCTP 패킷이다"라고 정의 | **Command Code**: "EID 할당(0x01)" 등 실제 수행할 관리 동작 |
| **유형 (Type)** | (없음) - 단순히 데이터를 운반 | **Message Type**: 페이로드의 클래스(제어, NVMe-MI 등)를 정의 |

즉, **SMBus는 물리적인 배달 통로** 역할을 수행하기 위한 정보를 담고 있고, **MCTP는 그 통로를 통해 흐르는 관리 데이터의 논리적인 의미와 목적지**를 담고 있는 것이라고 이해하시면 됩니다.

## nvme-mi command 예제

NVMe-MI(Management Interface) 명령은 **SMBus(물리 계층)** 위에 **MCTP(전송 계층)** 패킷이 실리고, 그 안에 다시 **NVMe-MI 메시지(응용 계층)**가 캡슐화되는 복합적인 구조를 가집니다.

가장 대표적인 예제인 **VPD Read (Vital Product Data 읽기)** 명령을 사용하여 실제 패킷 구조가 어떻게 구성되는지 단계별로 설명해 드리겠습니다.

### 예제 시나리오

* **송신자 (Requester):** BMC (물리 주소: 0x10, EID: 0x14)
* **수신자 (Responder):** NVMe SSD (물리 주소: 0x3A, EID: 0x0A)
* **작업:** SSD의 VPD 데이터를 읽기 위해 NVMe-MI 메시지를 전송함.

---

### 1. NVMe-MI 패킷 구조 (SMBus 위에서의 모습)

전체 패킷은 SMBus의 **Block Write** 프로토콜을 기반으로 하며, 다음과 같은 순서로 바이트가 배치됩니다.

| 순서 | 필드명 | 값 (예시) | 설명 |
| :--- | :--- | :--- | :--- |
| **1** | **Destination Address** | 0x74 (0x3A<<1) | SSD의 7비트 물리 주소 + Write 비트(0) |
| **2** | **SMBus Command Code** | **0x0F** | **MCTP 전용 코드** (항상 0x0F 고정) |
| **3** | **Byte Count** | N | 이후 따라오는 데이터의 총 바이트 수 |
| **4** | **Source Slave Address** | 0x21 | BMC의 물리 주소(0x10<<1) + **MCTP 구분 비트(1)** |
| **5** | **MCTP Header Version** | 0x01 | MCTP 규격 버전 (현재 0001b) |
| **6** | **Destination EID** | **0x0A** | 수신 장치(SSD)의 논리 주소 |
| **7** | **Source EID** | **0x14** | 송신 장치(BMC)의 논리 주소 |
| **8** | **MCTP Flags** | 0xC1 | **SOM(1), EOM(1)**, Seq#(0), Msg Tag(1) |
| **9** | **MCTP Message Type** | **0x04** | **NVMe-MI 메시지 유형** 식별자 |
| **10** | **NVMe-MI Header** | Opcode 등 | 실제 VPD Read를 지시하는 NVMe 관리 헤더 |
| **11** | **NVMe-MI Data** | (가변) | 명령에 필요한 추가 파라미터 |
| **12** | **PEC** | CRC-8 | 데이터 무결성을 위한 **Packet Error Code** |

---

### 2. 주요 핵심 필드 상세 설명

#### ① SMBus Command Code (0x0F) vs MCTP Message Type (0x04)

* **0x0F (SMBus 계층):** 하드웨어 선로 상에서 이 데이터가 일반적인 SMBus 데이터가 아니라 **"MCTP 패킷"**임을 선언합니다.
* **0x04 (MCTP 계층):** MCTP 패킷 내부의 페이로드가 **"NVMe-MI 관리 메시지"**임을 나타냅니다. 만약 장치 초기화 중이었다면 이 자리에 제어 메시지인 0x00이 들어갔을 것입니다.

#### ② EID (Endpoint ID)의 역할

* 물리 주소(0x3A)는 SMBus 선로에서 데이터를 전달하기 위해 사용되지만, **EID(0x0A)**는 MCTP 네트워크 상의 논리적인 주소입니다. 만약 SSD가 여러 개의 브릿지를 거쳐 연결되어 있더라도, 최종 목적지는 이 EID를 보고 찾아가게 됩니다.

#### ③ SOM(Start of Message) 및 EOM(End of Message)

* NVMe-MI 메시지는 최대 4224바이트까지 가능하지만, MCTP 패킷 하나는 보통 **64바이트(BTU)**로 제한됩니다.
* 예제에서는 VPD Read 명령어가 짧아 패킷 하나에 다 담기므로 **SOM과 EOM이 모두 1**로 설정되었습니다. 만약 메시지가 길어 여러 패킷으로 나뉜다면 첫 패킷은 SOM=1, 중간은 0, 마지막은 EOM=1이 됩니다.

#### ④ Source Slave Address의 LSB (Bit 0)

* SMBus 4번째 바이트에 들어가는 소스 주소의 최하위 비트는 항상 **1b**로 설정됩니다. 이는 기존의 IPMI 프로토콜(LSB=0b)과 동일한 선로에서 혼선 없이 MCTP를 구분해내기 위한 안티 에일리언싱(Anti-aliasing) 장치입니다.

#### ⑤ PEC (Packet Error Code)

* MCTP over SMBus에서는 데이터 신뢰성을 위해 패킷 마지막에 반드시 1바이트의 **PEC(CRC-8)**를 붙여야 합니다. 수신측은 이 값을 계산하여 데이터에 노이즈가 섞였는지 검증합니다.

이러한 구조를 통해 관리 컨트롤러는 호스트 OS의 도움 없이도(Out-of-Band) 하드웨어 수준에서 직접 SSD의 정보를 읽어오거나 제어할 수 있게 됩니다.

## 구현 예제

NVMe-MI(NVMe Management Interface)를 이용한 장치 제어 프로그램 개발을 위한 **MCTP 및 SMBus 기술 학습 가이드라인**을 정리해 드립니다. 이 가이드라인은 하부 물리 계층부터 상위 관리 프로토콜까지 단계별로 구성되었습니다.

---

### 🟢 1단계: 전체 시스템 아키텍처 이해 (OSI 7계층 관점)

프로그램을 작성하기 전, 데이터가 흐르는 계층 구조를 먼저 파악해야 합니다.

* **L4 (Application):** **NVMe-MI Message** (최대 4224바이트, 펌웨어 업데이트/상태 확인 명령).
* **L3 (Transport):** **MCTP** (메시지를 64바이트 단위 패킷으로 분할 및 라우팅).
* **L2 (Data Link):** **MCTP SMBus Binding** (SMBus Block Write 프로토콜 사용).
* **L1 (Physical):** **SMBus/I2C** (2-Wire 하드웨어 선로).

---

### 🟡 2단계: MCTP 베이스 프로토콜 (DSP0236) 핵심 학습

논리적 주소 지정과 데이터 분할/조립 로직의 핵심입니다.

1. **EID (Endpoint ID) 주소 체계:**
    * 각 장치는 8비트의 논리 주소(EID)를 가집니다. EID 0은 할당 전 물리 주소 기반 통신용(Null EID)입니다.
2. **MCTP 전송 헤더 (Transport Header):** 모든 패킷에 공통으로 포함되는 32비트 정보입니다.
    * **SOM (Start of Message) / EOM (End of Message):** 메시지의 시작과 끝 패킷을 구분합니다.
    * **Pkt Seq # (2비트):** 패킷 순서를 보장합니다 (Modulo 4).
    * **Msg Tag (3비트):** 동일한 소스/목적지 간 여러 메시지를 병렬로 처리할 때 구분자로 사용합니다.
3. **메시지 분해 및 조립 (Disassembly & Assembly):**
    * NVMe-MI 메시지는 크기가 크므로, 프로그램에서 이를 **64바이트(BTU)** 단위 패킷으로 쪼개고, 수신 시에는 Seq #를 확인하며 다시 합치는 로직이 필수입니다.

---

### 🔵 3단계: SMBus 전송 바인딩 (DSP0237) 핵심 학습

MCTP 패킷이 실제 SMBus 프레임 안에 어떻게 실리는지 이해해야 합니다.

1. **캡슐화 규칙:** MCTP over SMBus는 **SMBus Block Write** 프로토콜을 사용합니다.
    * **Command Code:** 항상 **0x0F**를 사용해야 MCTP 트래픽으로 인식됩니다.
    * **Byte Count:** 데이터의 길이를 표시합니다.
    * **PEC (Packet Error Code):** 데이터 무결성을 위해 마지막에 1바이트 CRC를 추가하고 검증해야 합니다.
2. **슬레이브 주소 지정:** 목적지 SMBus 주소(7비트) 뒤에 읽기/쓰기 비트를 붙여 통신합니다.

---

### 🟠 4단계: MCTP 제어 명령 (Control Protocol)

장치 초기화를 위해 반드시 구현해야 하는 기본 API입니다.

* **`Set Endpoint ID` (0x01):** 장치에 EID를 할당하여 통신 준비를 마칩니다.
* **`Get MCTP Version Support` (0x04):** 장치가 지원하는 MCTP 규격 버전을 확인합니다.
* **`Get Message Type Support` (0x05):** 해당 엔드포인트가 **NVMe-MI (Type 0x04)**를 지원하는지 확인합니다.

---

### 💻 5단계: 구현 예제 및 도구 활용

#### 1. libmctp 라이브러리 참조

바닥부터 모든 코드를 짜기보다 OpenBMC 프로젝트의 **libmctp** 소스를 분석하는 것이 가장 효율적입니다.

* `mctp_init()`: 코어 스택 초기화.
* `mctp_smbus_init()`: SMBus 하드웨어 바인딩 초기화.
* `mctp_message_tx()`: 상위 메시지를 보내면 자동으로 패킷 분할하여 전송.

#### 2. 메시지 구성 예시 (Pseudocode)

NVMe-MI 헬스 체크 명령을 보낼 때의 흐름입니다.

```c
// 1. NVMe-MI 관리 메시지 생성 (최대 4224 bytes)
uint8_t mi_msg[] = { ...NVMe_MI_Header, ...Payload... };

// 2. MCTP 패킷 생성 및 전송 로직 (64바이트 BTU 기준)
// SOM=1, EOM=0, Seq=0, Tag=1 로 첫 패킷 구성
// SOM=0, EOM=0, Seq=1, Tag=1 로 중간 패킷들 구성
// SOM=0, EOM=1, Seq=n, Tag=1 로 마지막 패킷 구성

// 3. SMBus 레이어로 캡슐화 (Block Write)
// [Dest_Addr | 0x0F | Byte_Count | Source_Addr | Hdr_Version | ...MCTP_Data... | PEC]
smbus_block_write(device_addr, 0x0F, packet_len, mctp_packet_data);
```

## mctp message type, command code, completion code의 종류

MCTP(Management Component Transport Protocol) 통신에서 상위 계층 데이터의 종류를 식별하는 **Message Type**, 제어 명령을 정의하는 **Command Code**, 그리고 명령 처리 결과를 나타내는 **Completion Code**에 대한 상세 설명입니다.

### 1. MCTP Message Type (메시지 유형)

MCTP 메시지 유형은 패킷 본체의 첫 번째 바이트(7비트)에 위치하며, 해당 메시지가 어떤 프로토콜 규격에 속하는지를 정의합니다.

* **0x00 (MCTP Control):** MCTP 네트워크의 초기화, 설정 및 유지를 위한 제어 메시지입니다.
* **0x01 (PLDM):** Platform Level Data Model 메시지입니다 (DSP0239 참조).
* **0x04 (NVMe Management Messages):** NVMe-MI 규격에 따른 관리 메시지입니다.
* **0x7E (Vendor Defined – PCI):** PCI 벤더 ID를 사용하는 제조사 정의 메시지입니다.
* **0x7F (Vendor Defined – IANA):** IANA 엔터프라이즈 번호를 사용하는 제조사 정의 메시지입니다.

### 2. MCTP Control Command Code (제어 명령 코드)

메시지 유형이 **0x00(MCTP Control)**일 때 사용되며, 네트워크 구성을 위해 수행할 구체적인 동작을 지정합니다. 주요 명령은 다음과 같습니다.

| 코드 | 명령 명칭 | 주요 역할 |
| :--- | :--- | :--- |
| **0x01** | **Set Endpoint ID** | 특정 물리 주소의 엔드포인트에 EID를 할당합니다. |
| **0x02** | **Get Endpoint ID** | 할당된 EID와 장치 유형(단순, 브릿지 등) 정보를 가져옵니다. |
| **0x03** | **Get Endpoint UUID** | 장치의 고유 식별자(UUID)를 요청합니다. |
| **0x04** | **Get MCTP Version Support** | 지원하는 MCTP 베이스 및 제어 규격 버전을 확인합니다. |
| **0x05** | **Get Message Type Support** | 엔드포인트가 지원하는 상위 메시지 유형 목록을 확인합니다. |
| **0x07** | **Resolve Endpoint ID** | 특정 EID에 도달하기 위한 물리 주소를 버스 오너에게 요청합니다. |
| **0x08** | **Allocate Endpoint IDs** | 하위 브릿지에게 사용할 EID 풀(Pool)을 할당합니다. |
| **0x0F** | **Query Hop** | 목적지까지의 브릿지 정보 및 지원되는 전송 단위(BTU)를 확인합니다. |
| **0x11** | **Query Rate Limit** | 엔드포인트의 데이터 수신 처리 능력 및 속도 제한 기능을 확인합니다. |

### 3. Completion Code (처리 결과 코드)

제어 프로토콜의 **응답(Response) 메시지**에만 포함되며, 요청된 명령의 성공 또는 실패 사유를 나타냅니다.

* **0x00 (SUCCESS):** 요청이 정상적으로 수락되고 완료되었습니다.
* **0x01 (ERROR):** 일반적인 오류 발생 시 사용되는 코드입니다.
* **0x02 (ERROR_INVALID_DATA):** 패킷 페이로드에 유효하지 않은 데이터나 매개변수가 포함되었습니다.
* **0x03 (ERROR_INVALID_LENGTH):** 메시지 본체의 길이가 예상보다 길거나 짧습니다.
* **0x04 (ERROR_NOT_READY):** 수신 측이 일시적인 상태 문제로 메시지를 처리할 준비가 되지 않았습니다.
* **0x05 (ERROR_UNSUPPORTED_CMD):** 수신한 명령 코드를 엔드포인트에서 지원하지 않습니다.
* **0x80 – 0xFF (COMMAND_SPECIFIC):** 각 개별 명령 규격에서 별도로 정의하여 사용하는 전용 오류 코드 범위입니다.

## 2 updates mctp message type, command code, completion code의 종류

이전 답변에서 다룬 내용은 개발에 가장 필수적인 핵심 요소들이었으며, 제공된 소스 자료(MCTP 베이스 규격 DSP0236)를 기준으로 확인한 **전체 목록**은 다음과 같습니다.

### 1. MCTP Message Type (전체 목록)

베이스 규격(DSP0236)에서는 공통적으로 사용되는 유형만 정의하며, 나머지는 별도 규격인 **DSP0239(IDs and Codes)**에서 상세히 다룹니다.

* **0x00 (MCTP Control):** 네트워크 초기화 및 관리용.
* **0x01 (PLDM):** Platform Level Data Model (DSP0241/0261 관련).
* **0x04 (NVMe-MI):** NVMe 관리 메시지 (대화 중 언급됨).
* **0x7E (Vendor Defined – PCI):** PCI 벤더 ID 기반 제조사 정의 메시지.
* **0x7F (Vendor Defined – IANA):** IANA 엔터프라이즈 번호 기반 제조사 정의 메시지.

### 2. MCTP Control Command Code (전체 목록)

소스의 **Table 12**에 정의된 모든 제어 명령 코드입니다.

| 코드 | 명령 명칭 | 코드 | 명령 명칭 |
| :--- | :--- | :--- | :--- |
| **0x01** | **Set Endpoint ID** | **0x0B** | **Prepare for Endpoint Discovery** |
| **0x02** | **Get Endpoint ID** | **0x0C** | **Endpoint Discovery** |
| **0x03** | **Get Endpoint UUID** | **0x0D** | **Discovery Notify** |
| **0x04** | **Get MCTP Version Support** | **0x0E** | **Get Network ID** |
| **0x05** | **Get Message Type Support** | **0x0F** | **Query Hop** |
| **0x06** | **Get Vendor Defined Message Support** | **0x10** | **Resolve UUID** |
| **0x07** | **Resolve Endpoint ID** | **0x11** | **Query Rate Limit** |
| **0x08** | **Allocate Endpoint IDs** | **0x12** | **Request TX Rate Limit** |
| **0x09** | **Routing Information Update** | **0x13** | **Update Rate Limit** |
| **0x0A** | **Get Routing Table Entries** | **0x14** | **Query Supported Interfaces** |
| **0xF0~0xFF** | **Transport Specific** (전송 매체별 전용 명령 범위) | | |

### 3. MCTP Control Completion Code (전체 목록)

소스의 **Table 13**에 정의된 모든 공통 처리 결과 코드입니다.

* **0x00 (SUCCESS):** 정상 완료.
* **0x01 (ERROR):** 일반적인 오류 (구체적 코드가 없을 때 사용).
* **0x02 (ERROR_INVALID_DATA):** 유효하지 않은 데이터 또는 파라미터.
* **0x03 (ERROR_INVALID_LENGTH):** 메시지 본체 길이가 규격과 맞지 않음.
* **0x04 (ERROR_NOT_READY):** 일시적인 준비 미비 상태.
* **0x05 (ERROR_UNSUPPORTED_CMD):** 지원하지 않는 명령 코드 수신.
* **0x80 – 0xFF (COMMAND_SPECIFIC):** 개별 명령 규격에서 별도로 정의한 전용 오류 코드들.

요약하자면, 일반적인 NVMe-MI 제어 프로그램 개발 시에는 이전 답변의 핵심 리스트만으로 충분하지만, **브릿징, 라우팅 테이블 관리, 또는 속도 제한(Rate Limiting)**과 같은 정교한 네트워크 제어가 필요한 경우에는 위 전체 목록에 포함된 명령들을 추가로 구현해야 합니다. 
