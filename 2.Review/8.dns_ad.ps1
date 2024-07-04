## https://chatgpt.com/share/b50dda96-77ff-4676-a470-b9a70dfd9600

# 역방향 조회 도메인 만들기
Add-DnsServerPrimaryZone -NetworkID 10.10.10.0/24 -ZoneFile "10.10.10.in-addr.arpa.dns"

# 도메인 컨트롤러 레코드 설정
$dnsRecords = @(
    @{ Name = "sa-vcsa-01"; IPv4Address = "10.10.10.10" },
    @{ Name = "sa-esxi-01"; IPv4Address = "10.10.10.11" },
    @{ Name = "sa-esxi-02"; IPv4Address = "10.10.10.12" },
    @{ Name = "sa-esxi-03"; IPv4Address = "10.10.10.13" }
)

foreach ($record in $dnsRecords) {
    Add-DnsServerResourceRecordA -Name $record.Name -ZoneName "vclass.local" -IPv4Address $record.IPv4Address
    $ptrName = $record.IPv4Address.Split('.')[-1]
    Add-DnsServerResourceRecordPtr -Name $ptrName -ZoneName "10.10.10.in-addr.arpa" -PtrDomainName "$($record.Name).vclass.local"
}

# AD 모듈 설치
Import-Module ActiveDirectory

# 주요 변수 설정
$dcpath = "DC=vclass,DC=local"
$ou = "Student"
$groupname = "Students"
$oupath = "OU=$ou,$dcpath"

# OU 만들기
New-ADOrganizationalUnit -Name $ou -Path $dcpath

# 보안 그룹 생성
New-ADGroup -Name $groupname -GroupCategory Security -GroupScope Global -DisplayName $groupname -Path $oupath

# AD 사용자 생성 및 그룹에 추가
for ($i = 0; $i -le 10; $i++) {
    $username = "S" + "{0:D2}" -f $i
    New-ADUser -Name $username -Path $oupath -Enabled $true -AccountPassword (ConvertTo-SecureString "VMware1!" -AsPlainText -force) -PasswordNeverExpires $true -PassThru
    Add-ADGroupMember -Identity $groupname -Members $username
}
