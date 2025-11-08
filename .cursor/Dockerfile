FROM ubuntu:22.04

# تجنب التفاعل أثناء التثبيت
ENV DEBIAN_FRONTEND=noninteractive

# تثبيت الأدوات الأساسية
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/*

# تثبيت Flutter SDK
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
    && flutter doctor \
    && flutter config --no-analytics \
    && flutter precache

# تثبيت Android SDK (للبناء على Android)
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && cd $ANDROID_HOME/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip -q commandlinetools-linux-9477386_latest.zip \
    && mv cmdline-tools latest \
    && rm commandlinetools-linux-9477386_latest.zip \
    && yes | sdkmanager --licenses || true \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# إنشاء مستخدم للتطوير
RUN useradd -m -s /bin/bash ubuntu \
    && chown -R ubuntu:ubuntu $FLUTTER_HOME \
    && chown -R ubuntu:ubuntu $ANDROID_HOME

# التبديل للمستخدم ubuntu
USER ubuntu
WORKDIR /home/ubuntu

# تعيين متغيرات البيئة للمستخدم
ENV PATH="/home/ubuntu/.pub-cache/bin:$PATH"
ENV PUB_CACHE="/home/ubuntu/.pub-cache"

# تهيئة Flutter للمستخدم
RUN flutter doctor -v

# نقطة الدخول الافتراضية
CMD ["/bin/bash"]

