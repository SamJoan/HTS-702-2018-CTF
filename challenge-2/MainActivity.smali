.class public Lcom/hackerone/mobile/challenge2/MainActivity;
.super Landroid/support/v7/app/AppCompatActivity;
.source "MainActivity.java"


# static fields
.field private static final hexArray:[C


# instance fields
.field TAG:Ljava/lang/String;

.field private cipherText:[B

.field mIndicatorDots:Lcom/andrognito/pinlockview/IndicatorDots;

.field private mPinLockListener:Lcom/andrognito/pinlockview/PinLockListener;

.field mPinLockView:Lcom/andrognito/pinlockview/PinLockView;


# direct methods
.method static constructor <clinit>()V
    .locals 1

    const-string v0, "native-lib"

    .line 66
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    const-string v0, "0123456789ABCDEF"

    .line 69
    invoke-virtual {v0}, Ljava/lang/String;->toCharArray()[C

    move-result-object v0

    sput-object v0, Lcom/hackerone/mobile/challenge2/MainActivity;->hexArray:[C

    return-void
.end method

.method public constructor <init>()V
    .locals 1

    .line 21
    invoke-direct {p0}, Landroid/support/v7/app/AppCompatActivity;-><init>()V

    const-string v0, "PinLock"

    .line 23
    iput-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->TAG:Ljava/lang/String;

    .line 29
    new-instance v0, Lcom/hackerone/mobile/challenge2/MainActivity$1;

    invoke-direct {v0, p0}, Lcom/hackerone/mobile/challenge2/MainActivity$1;-><init>(Lcom/hackerone/mobile/challenge2/MainActivity;)V

    iput-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mPinLockListener:Lcom/andrognito/pinlockview/PinLockListener;

    return-void
.end method

.method static synthetic access$000(Lcom/hackerone/mobile/challenge2/MainActivity;)[B
    .locals 0

    .line 21
    iget-object p0, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->cipherText:[B

    return-object p0
.end method

.method public static bytesToHex([B)Ljava/lang/String;
    .locals 6

    .line 71
    array-length v0, p0

    mul-int/lit8 v0, v0, 0x2

    new-array v0, v0, [C

    const/4 v1, 0x0

    .line 72
    :goto_0
    array-length v2, p0

    if-ge v1, v2, :cond_0

    .line 73
    aget-byte v2, p0, v1

    and-int/lit16 v2, v2, 0xff

    mul-int/lit8 v3, v1, 0x2

    .line 74
    sget-object v4, Lcom/hackerone/mobile/challenge2/MainActivity;->hexArray:[C

    ushr-int/lit8 v5, v2, 0x4

    aget-char v4, v4, v5

    aput-char v4, v0, v3

    add-int/lit8 v3, v3, 0x1

    .line 75
    sget-object v4, Lcom/hackerone/mobile/challenge2/MainActivity;->hexArray:[C

    and-int/lit8 v2, v2, 0xf

    aget-char v2, v4, v2

    aput-char v2, v0, v3

    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 77
    :cond_0
    new-instance p0, Ljava/lang/String;

    invoke-direct {p0, v0}, Ljava/lang/String;-><init>([C)V

    return-object p0
.end method


# virtual methods
.method public native getKey(Ljava/lang/String;)[B
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 1

    .line 82
    invoke-super {p0, p1}, Landroid/support/v7/app/AppCompatActivity;->onCreate(Landroid/os/Bundle;)V

    const p1, 0x7f09001b

    .line 83
    invoke-virtual {p0, p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->setContentView(I)V

    .line 85
    new-instance p1, Lorg/libsodium/jni/encoders/Hex;

    invoke-direct {p1}, Lorg/libsodium/jni/encoders/Hex;-><init>()V

    const-string v0, "9646D13EC8F8617D1CEA1CF4334940824C700ADF6A7A3236163CA2C9604B9BE4BDE770AD698C02070F571A0B612BBD3572D81F99"

    invoke-virtual {p1, v0}, Lorg/libsodium/jni/encoders/Hex;->decode(Ljava/lang/String;)[B

    move-result-object p1

    iput-object p1, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->cipherText:[B

    const p1, 0x7f07004f

    .line 87
    invoke-virtual {p0, p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->findViewById(I)Landroid/view/View;

    move-result-object p1

    check-cast p1, Lcom/andrognito/pinlockview/PinLockView;

    iput-object p1, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mPinLockView:Lcom/andrognito/pinlockview/PinLockView;

    .line 88
    iget-object p1, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mPinLockView:Lcom/andrognito/pinlockview/PinLockView;

    iget-object v0, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mPinLockListener:Lcom/andrognito/pinlockview/PinLockListener;

    invoke-virtual {p1, v0}, Lcom/andrognito/pinlockview/PinLockView;->setPinLockListener(Lcom/andrognito/pinlockview/PinLockListener;)V

    const p1, 0x7f070039

    .line 90
    invoke-virtual {p0, p1}, Lcom/hackerone/mobile/challenge2/MainActivity;->findViewById(I)Landroid/view/View;

    move-result-object p1

    check-cast p1, Lcom/andrognito/pinlockview/IndicatorDots;

    iput-object p1, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mIndicatorDots:Lcom/andrognito/pinlockview/IndicatorDots;

    .line 91
    iget-object p1, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mPinLockView:Lcom/andrognito/pinlockview/PinLockView;

    iget-object p0, p0, Lcom/hackerone/mobile/challenge2/MainActivity;->mIndicatorDots:Lcom/andrognito/pinlockview/IndicatorDots;

    invoke-virtual {p1, p0}, Lcom/andrognito/pinlockview/PinLockView;->attachIndicatorDots(Lcom/andrognito/pinlockview/IndicatorDots;)V

    return-void
.end method

.method public native resetCoolDown()V
.end method
